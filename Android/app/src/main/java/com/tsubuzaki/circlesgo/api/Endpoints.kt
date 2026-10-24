package com.tsubuzaki.circlesgo.api

import com.tsubuzaki.circlesgo.BuildConfig

object Endpoints {
    const val circleMsAuthEndpoint: String = BuildConfig.CIRCLEMS_AUTH_ENDPOINT
    const val circleMsAPIEndpoint: String = BuildConfig.CIRCLEMS_API_ENDPOINT

    const val CANCEL_URL_SCHEMA =
        "circles-app:/?error=access_denied&error_description=user%20access%20denied&state=auth"
}
