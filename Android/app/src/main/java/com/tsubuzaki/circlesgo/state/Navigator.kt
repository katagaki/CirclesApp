package com.tsubuzaki.circlesgo.state

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.edit
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.LayoutCatalogMapping
import com.tsubuzaki.circlesgo.database.types.LayoutType
import com.tsubuzaki.circlesgo.wayfinding.GuideSession
import com.tsubuzaki.circlesgo.wayfinding.PlannedRoute
import com.tsubuzaki.circlesgo.wayfinding.RouteAction
import com.tsubuzaki.circlesgo.wayfinding.RouteClosure
import com.tsubuzaki.circlesgo.wayfinding.RouteClosureLine
import com.tsubuzaki.circlesgo.wayfinding.RouteHall
import com.tsubuzaki.circlesgo.wayfinding.RoutePlanner
import com.tsubuzaki.circlesgo.wayfinding.RoutePoint
import com.tsubuzaki.circlesgo.wayfinding.RouteRect
import com.tsubuzaki.circlesgo.wayfinding.RouteStep
import com.tsubuzaki.circlesgo.wayfinding.RouteStop
import com.tsubuzaki.circlesgo.wayfinding.RouteStopRequest
import com.tsubuzaki.circlesgo.wayfinding.RouteTable
import com.tsubuzaki.circlesgo.wayfinding.WalkableMap
import com.tsubuzaki.circlesgo.wayfinding.closureCells
import com.tsubuzaki.circlesgo.wayfinding.entrances
import com.tsubuzaki.circlesgo.wayfinding.instruction
import com.tsubuzaki.circlesgo.wayfinding.narrowestCrossing
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/** Plans a walk through the favourites on the open hall map and steps through it. */
class Navigator(
    private val context: Context,
    private val database: CatalogDatabase,
    private val visitsState: VisitsState,
    private val scope: CoroutineScope
) {

    data class GuideContext(
        val eventNumber: Int,
        val mapID: Int,
        val mapName: String,
        val hall: ComiketHall,
        val day: Int,
        val layouts: Map<LayoutCatalogMapping, List<Int>>,
        val favoriteColors: Map<Int, WebCatalogColor>,
        val visitedCircleIDs: List<Int>,
        val colorPriority: List<WebCatalogColor>?
    )

    enum class Mode { EFFICIENT, PRIORITIZED }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var route by mutableStateOf<PlannedRoute?>(null)
        private set
    var stepIndex by mutableStateOf(0)
        private set
    var isPlanning by mutableStateOf(false)
        private set
    var origin by mutableStateOf<RoutePoint?>(null)
        private set
    var closures by mutableStateOf<List<RouteClosure>>(emptyList())
        private set
    var skippedSpaces by mutableStateOf<List<String>>(emptyList())
        private set
    var halls by mutableStateOf<List<RouteHall>>(emptyList())
        private set
    var pendingPoint by mutableStateOf<RoutePoint?>(null)
        private set
    var selectedClosureID by mutableStateOf<String?>(null)
        private set
    var isNoStopsAlertPresented by mutableStateOf(false)
        private set
    var isTrapped by mutableStateOf(false)
        private set
    var isFinished by mutableStateOf(false)
        private set

    /** Where a visitor can walk in the open hall, kept once read off the map image. */
    var walkableMap by mutableStateOf<WalkableMap?>(null)
        private set

    /** Favourites of each colour on the open map, for the colour order screen. */
    var priorityCounts by mutableStateOf<Map<WebCatalogColor, Int>>(emptyMap())
        private set

    /** Set while the colour order screen is up; called with the colours chosen. */
    var priorityRequest by mutableStateOf<((List<WebCatalogColor>) -> Unit)?>(null)
        private set

    var hasSeenOnboarding by mutableStateOf(prefs.getBoolean(HAS_SEEN_ONBOARDING_KEY, false))
        private set
    var hidesSafetyAlert by mutableStateOf(prefs.getBoolean(HIDES_SAFETY_ALERT_KEY, false))
        private set

    private var guideContext: GuideContext? = null
    private var remainingStopIDs: Set<Int>? = null
    private var walkableMapKey: String? = null
    private var planningJob: Job? = null
    private var retryJob: Job? = null
    private var hallsJob: Job? = null
    private var savedSession: GuideSession? = GuideSession.load(context)

    val isActive: Boolean get() = route != null || isPlanning || isTrapped

    val currentStep: RouteStep?
        get() = route?.steps?.getOrNull(stepIndex)

    val currentStop: RouteStop?
        get() {
            val step = currentStep ?: return null
            return route?.stops?.getOrNull(step.stopIndex)
        }

    /**
     * Where the visitor is standing: the start of the step they are on while a route is up,
     * so it follows them as they step through it, otherwise the spot they long-pressed.
     */
    val currentLocation: RoutePoint?
        get() {
            if (isFinished) currentStep?.path?.lastOrNull()?.let { return it }
            currentStep?.path?.firstOrNull()?.let { return it }
            return origin
        }

    val currentInstruction: String?
        get() {
            val step = currentStep ?: return null
            val stop = currentStop ?: return null
            return step.instruction(context, stop)
        }

    val activeClosures: List<RouteClosure> get() = closures.filter { it.isActive }

    val canReportBlocked: Boolean
        get() = when (currentStep?.action) {
            null, is RouteAction.Begin, is RouteAction.Entrance, is RouteAction.Enter -> false
            is RouteAction.Turn, is RouteAction.Arrive, is RouteAction.Exit -> true
        }

    fun setHasSeenOnboarding() {
        hasSeenOnboarding = true
        prefs.edit { putBoolean(HAS_SEEN_ONBOARDING_KEY, true) }
    }

    fun setHidesSafetyAlert() {
        hidesSafetyAlert = true
        prefs.edit { putBoolean(HIDES_SAFETY_ALERT_KEY, true) }
    }

    var storedColorOrder: String
        get() = prefs.getString(COLOR_PRIORITY_KEY, "") ?: ""
        set(value) = prefs.edit { putString(COLOR_PRIORITY_KEY, value) }

    var storedColorExclusions: String
        get() = prefs.getString(COLOR_EXCLUDED_KEY, "") ?: ""
        set(value) = prefs.edit { putString(COLOR_EXCLUDED_KEY, value) }

    fun openPriority(counts: Map<WebCatalogColor, Int>, onChoose: (List<WebCatalogColor>) -> Unit) {
        priorityCounts = counts
        priorityRequest = onChoose
    }

    fun closePriority() {
        priorityRequest = null
    }

    fun start(guideContext: GuideContext) {
        this.guideContext = guideContext
        savedSession = null
        remainingStopIDs = null
        plan()
    }

    fun dismissNoStops() {
        isNoStopsAlertPresented = false
    }

    fun plan() {
        val guide = guideContext ?: return
        planningJob?.cancel()
        isPlanning = true
        planningJob = scope.launch {
            val key = mapKey(guide.mapID, guide.day)
            val outcome = makeRoute(
                guide, origin, activeClosures, remainingStopIDs,
                if (walkableMapKey == key) walkableMap else null
            )
            if (!isActive) return@launch
            outcome.map?.let {
                walkableMap = it
                walkableMapKey = key
            }
            if (outcome.halls.isNotEmpty()) halls = outcome.halls
            val planned = outcome.route?.takeIf { it.steps.isNotEmpty() }
            val trapped = planned == null && outcome.route?.skippedSpaces?.isNotEmpty() == true
            route = planned
            skippedSpaces = outcome.route?.skippedSpaces ?: emptyList()
            stepIndex = 0
            isFinished = false
            isPlanning = false
            isTrapped = trapped
            if (planned == null && !trapped) isNoStopsAlertPresented = true
            persist()
            if (trapped) retryWhenClosuresLapse()
        }
    }

    // Long Press

    /**
     * Holds a long-pressed spot, in the map's display coordinates, until the visitor says
     * whether they are standing there or the way is closed there.
     */
    fun hold(x: Float, y: Float, spaceSize: Int) {
        val scale = PLANNING_SPACE_SIZE / spaceSize
        selectedClosureID = null
        pendingPoint = RoutePoint(x * scale, y * scale)
    }

    /**
     * The aisle a closure at the long-pressed spot would seal, drawn before the visitor
     * chooses to close it, so they can see which way it runs.
     */
    val pendingClosureLine: Pair<RoutePoint, RoutePoint>?
        get() {
            val point = pendingPoint ?: return null
            val map = walkableMap ?: return null
            return RoutePlanner.line(map.closureCells(point), map)
        }

    /** The lines across every closed way, drawn whether or not a route is up. */
    val closureLines: List<RouteClosureLine>
        get() {
            val map = walkableMap ?: return emptyList()
            return RoutePlanner.seal(activeClosures, map).second
        }

    fun cancelHold() {
        pendingPoint = null
        selectedClosureID = null
    }

    fun setOriginAtHold() {
        val point = pendingPoint ?: return
        origin = point
        pendingPoint = null
        keepRemainingStops()
        if (guideContext != null) plan()
    }

    /**
     * The lines where neighbouring halls meet. Where the printed ranges overlap, the
     * boundary is taken as the middle of the overlap.
     */
    val hallBoundaries: List<Double>
        get() = halls.zipWithNext { left, right -> (left.rect.maxX + right.rect.minX) / 2.0 }

    /**
     * Loads the halls of the open map, so their boundaries can be closed off before a
     * route has been planned on it.
     */
    fun loadHalls(mapID: Int, hall: ComiketHall?, day: Int?) {
        hallsJob?.cancel()
        hallsJob = scope.launch {
            val fetcher = DataFetcher(database.getTextDatabase())
            halls = fetcher.hallAreas(mapID)
            if (hall == null || day == null) return@launch
            val key = mapKey(mapID, day)
            if (walkableMapKey == key) return@launch
            val map = buildMap(hall, day, tables(mapID)) ?: return@launch
            if (!isActive) return@launch
            walkableMap = map
            walkableMapKey = key
        }
    }

    fun closeHallsAtHold() {
        val point = pendingPoint ?: return
        val boundary = hallBoundaries.minByOrNull { abs(it - point.x) } ?: return
        closures = closures + RouteClosure.create(RoutePoint(boundary, point.y), hallBoundaryX = boundary)
        pendingPoint = null
        replanFromCurrentStep()
    }

    fun closePathAtHold() {
        val point = pendingPoint ?: return
        closures = closures + RouteClosure.create(point)
        pendingPoint = null
        replanFromCurrentStep()
    }

    // Closures

    /**
     * The way ahead is closed: seals off the aisle the current step turns into, or the
     * stretch it walks if it ends at a stop, and plans again from where the step began.
     */
    fun reportBlocked() {
        val route = route ?: return
        val step = currentStep ?: return
        if (!canReportBlocked) return
        val next = route.steps.getOrNull(stepIndex + 1)
        val stretch = if (!step.isArrival && next != null && next.stopIndex == step.stopIndex && next.path.size > 1) {
            next.path.take(12)
        } else {
            step.path
        }
        val crossing = walkableMap?.narrowestCrossing(stretch)
        val closure = if (crossing != null) {
            RouteClosure.create(crossing.first, across = crossing.second)
        } else {
            RouteClosure.create(stretch[stretch.size / 2])
        }
        closures = closures + closure
        replanFromCurrentStep()
    }

    fun selectClosure(x: Float, y: Float, spaceSize: Int): Boolean {
        val scale = PLANNING_SPACE_SIZE / spaceSize
        val targetX = x * scale
        val targetY = y * scale
        val closure = activeClosures.firstOrNull {
            hypot(it.point.x - targetX, it.point.y - targetY) < PLANNING_SPACE_SIZE
        } ?: return false
        pendingPoint = null
        selectedClosureID = closure.id
        return true
    }

    fun reopenSelectedClosure() {
        val id = selectedClosureID ?: return
        closures = closures.filter { it.id != id }
        selectedClosureID = null
        replanFromCurrentStep()
    }

    val selectedClosure: RouteClosure? get() = closures.firstOrNull { it.id == selectedClosureID }

    val selectedClosureIsHallBoundary: Boolean get() = selectedClosure?.hallBoundaryX != null

    fun clearClosures() {
        hallsJob?.cancel()
        closures = emptyList()
        halls = emptyList()
        walkableMap = null
        walkableMapKey = null
        pendingPoint = null
        selectedClosureID = null
    }

    /**
     * Every way out is closed. Closures lapse on their own, so the route is planned again
     * as soon as the first of them does.
     */
    private fun retryWhenClosuresLapse() {
        retryJob?.cancel()
        val next = activeClosures.minOfOrNull { it.expiresAt } ?: return
        retryJob = scope.launch {
            delay(max(1000L, next - System.currentTimeMillis() + 1000L))
            if (isTrapped) plan()
        }
    }

    private fun keepRemainingStops() {
        val route = route ?: return
        val step = currentStep ?: return
        remainingStopIDs = route.stops.drop(step.stopIndex).map { it.id }.toSet()
    }

    private fun replanFromCurrentStep() {
        if (guideContext == null) return
        val step = currentStep
        if (step != null && !step.isStart) step.path.firstOrNull()?.let { origin = it }
        keepRemainingStops()
        plan()
    }

    fun next() {
        val route = route ?: return
        if (stepIndex + 1 >= route.steps.size) return
        stepIndex += 1
        persist()
    }

    fun previous() {
        if (isFinished) {
            isFinished = false
            persist()
            return
        }
        if (stepIndex <= 0) return
        stepIndex -= 1
        persist()
    }

    /**
     * Moves past the current step without marking anything; past the last stop, the
     * visitor is told they are done, and the route stays up until they end it.
     */
    fun skip() {
        val route = route
        if (route != null && stepIndex + 1 < route.steps.size) {
            next()
        } else if (route != null && !isFinished) {
            isFinished = true
            persist()
        }
    }

    fun markVisitedAndContinue() {
        val stop = currentStop ?: return
        val eventNumber = guideContext?.eventNumber ?: return
        visitsState.markVisited(stop.circleID, eventNumber)
        skip()
    }

    fun end() {
        planningJob?.cancel()
        retryJob?.cancel()
        route = null
        origin = null
        pendingPoint = null
        selectedClosureID = null
        skippedSpaces = emptyList()
        isTrapped = false
        isFinished = false
        isPlanning = false
        stepIndex = 0
        guideContext = null
        remainingStopIDs = null
        savedSession = null
        GuideSession.remove(context)
    }

    // Persistence

    private fun persist() {
        val guide = guideContext
        if (guide == null || (route == null && !isTrapped)) {
            GuideSession.remove(context)
            return
        }
        GuideSession(
            eventNumber = guide.eventNumber, mapID = guide.mapID, day = guide.day,
            favoriteColors = guide.favoriteColors.mapValues { it.value.value },
            visitedCircleIDs = guide.visitedCircleIDs,
            colorPriority = guide.colorPriority?.map { it.value },
            route = route, stepIndex = stepIndex, origin = origin,
            closures = activeClosures, skippedSpaces = skippedSpaces,
            remainingStopIDs = remainingStopIDs, isTrapped = isTrapped, isFinished = isFinished
        ).save(context)
    }

    /**
     * Picks up the session left when the app last closed, once the map it was on is open
     * again with its layouts loaded.
     */
    fun resume(
        eventNumber: Int, mapID: Int, mapName: String, hall: ComiketHall, day: Int,
        layouts: Map<LayoutCatalogMapping, List<Int>>
    ) {
        val session = savedSession ?: return
        if (isActive || guideContext != null || layouts.isEmpty() ||
            session.eventNumber != eventNumber || session.mapID != mapID || session.day != day
        ) return
        savedSession = null
        guideContext = GuideContext(
            eventNumber = eventNumber, mapID = mapID, mapName = mapName, hall = hall, day = day,
            layouts = layouts,
            favoriteColors = session.favoriteColors.mapValues { WebCatalogColor.fromValue(it.value) },
            visitedCircleIDs = session.visitedCircleIDs,
            colorPriority = session.colorPriority?.map { WebCatalogColor.fromValue(it) }
        )
        remainingStopIDs = session.remainingStopIDs
        closures = session.closures.filter { it.isActive }
        origin = session.origin
        val saved = session.route
        if (saved == null || session.isTrapped || saved.steps.isEmpty()) {
            plan()
            return
        }
        route = saved
        stepIndex = session.stepIndex.coerceIn(0, saved.steps.size - 1)
        skippedSpaces = session.skippedSpaces
        isFinished = session.isFinished
    }

    // Planning

    private class Outcome(
        val route: PlannedRoute?,
        val map: WalkableMap?,
        val halls: List<RouteHall> = emptyList()
    )

    private suspend fun tables(mapID: Int): List<RouteTable> {
        val fetcher = DataFetcher(database.getTextDatabase())
        val layouts = fetcher.layoutMappings(mapID, true)
        val blockNames = withContext(Dispatchers.IO) { database.blocks().associate { it.id to it.name } }
        return layouts.map { layout ->
            RouteTable(
                rect = RouteRect(
                    layout.positionX.toDouble(), layout.positionY.toDouble(),
                    PLANNING_SPACE_SIZE, PLANNING_SPACE_SIZE
                ),
                blockName = blockNames[layout.blockID] ?: "",
                opensSideways = layout.opensSideways
            )
        }
    }

    private suspend fun buildMap(hall: ComiketHall, day: Int, tables: List<RouteTable>): WalkableMap? =
        withContext(Dispatchers.Default) {
            val image = database.mapImage(hall.value, day, true) ?: return@withContext null
            runCatching { WalkableMap.build(image, tables, hall.entrances) }.getOrNull()
        }

    private suspend fun makeRoute(
        guide: GuideContext, origin: RoutePoint?, closures: List<RouteClosure>,
        remainingStopIDs: Set<Int>?, cached: WalkableMap?
    ): Outcome {
        val stopIDs = mutableListOf<Int>()
        val layoutsByStop = HashMap<Int, Pair<LayoutCatalogMapping, Int>>()
        for ((layout, webCatalogIDs) in guide.layouts) {
            for (webCatalogID in webCatalogIDs) {
                val color = guide.favoriteColors[webCatalogID] ?: continue
                if (remainingStopIDs != null && webCatalogID !in remainingStopIDs) continue
                if (guide.colorPriority != null && color !in guide.colorPriority) continue
                stopIDs.add(webCatalogID)
                layoutsByStop[webCatalogID] = layout to webCatalogIDs.size
            }
        }
        if (stopIDs.isEmpty()) return Outcome(null, null)

        val fetcher = DataFetcher(database.getTextDatabase())
        val tables = tables(guide.mapID)
        val tableLayouts = fetcher.layoutMappings(guide.mapID, true)
        val circles = fetcher.routeCircles(stopIDs)
        val visited = fetcher.webCatalogIDs(guide.visitedCircleIDs).toSet()
        val halls = fetcher.hallAreas(guide.mapID)

        val space = PLANNING_SPACE_SIZE
        val positions = tableLayouts.associateBy { it.viewID() }
        val requests = stopIDs.filter { it !in visited }.mapNotNull { webCatalogID ->
            val circle = circles[webCatalogID] ?: return@mapNotNull null
            val (layout, count) = layoutsByStop[webCatalogID] ?: return@mapNotNull null
            val position = positions[layout.viewID()] ?: return@mapNotNull null
            val opensSideways = layout.opensSideways
            val isReversed = layout.layoutType == LayoutType.A_ON_BOTTOM || layout.layoutType == LayoutType.A_ON_RIGHT
            val total = max(count, 1).toDouble()
            val index = min(
                if (isReversed) count - 1 - circle.spaceNumberSuffix else circle.spaceNumberSuffix,
                count - 1
            ).toDouble()
            val baseX = position.positionX.toDouble()
            val baseY = position.positionY.toDouble()
            val rect = if (opensSideways) {
                RouteRect(baseX + index * space / total, baseY, space / total, space)
            } else {
                RouteRect(baseX, baseY + index * space / total, space, space / total)
            }
            val color = guide.favoriteColors[webCatalogID] ?: WebCatalogColor.UNCOLORED
            RouteStopRequest(
                webCatalogID = webCatalogID, circleID = circle.circleID, name = circle.name,
                spaceName = circle.spaceName, spaceRect = rect, opensSideways = opensSideways,
                rank = guide.colorPriority?.indexOf(color)?.takeIf { it >= 0 } ?: 0,
                colorRawValue = color.value
            )
        }
        if (requests.isEmpty()) return Outcome(null, null)

        val map = cached ?: buildMap(guide.hall, guide.day, tables) ?: return Outcome(null, null)
        val route = withContext(Dispatchers.Default) {
            RoutePlanner.plan(map, requests, origin, closures, halls)
        }
        return Outcome(route, map, halls)
    }

    companion object {
        const val PLANNING_SPACE_SIZE: Double = 40.0

        private const val PREFS_NAME = "route_prefs"
        private const val HAS_SEEN_ONBOARDING_KEY = "Route.HasSeenOnboarding"
        private const val HIDES_SAFETY_ALERT_KEY = "Route.HidesSafetyAlert"
        private const val COLOR_PRIORITY_KEY = "Route.ColorPriority"
        private const val COLOR_EXCLUDED_KEY = "Route.ColorExcluded"

        private fun mapKey(mapID: Int, day: Int): String = "$day-$mapID"

        private val LayoutCatalogMapping.opensSideways: Boolean
            get() = layoutType != LayoutType.A_ON_TOP && layoutType != LayoutType.A_ON_BOTTOM
    }
}
