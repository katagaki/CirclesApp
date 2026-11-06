# Offline Indicators

Standalone harness for comparing offline indicators for issue 163. It mocks the CiRCLES map shell, including the real panel detents (88, 360, large), and shares no code with the app.

## Run

```sh
xcodegen generate
open OfflineIndicators.xcodeproj
```

Use the panel to switch the indicator, state, time left and language. At the compact detent, use the arrows.

## Indicators

| Variant | `-variant` | Where it sits |
| --- | --- | --- |
| Current gradient | `current` | Top of the screen, as shipped |
| 1 Status pill | `pill` | Under the toolbar, expands in place |
| 2 Banner | `banner` | Under the toolbar, with an inline action |
| 3 Toolbar button | `toolbar` | Toolbar icon that opens a menu |
| 4 Collapsing toast | `toast` | Explains itself for 6 seconds, then shrinks to a chip |
| 5 Panel strip | `panel` | Top of the panel, icon at the compact detent |

## Launch arguments

`-variant <above>`, `-pillStyle glass|tinted|solid|ring|compact`, `-status online|manual|lost`, `-timeLeft days|hours`, `-lang en|ja`, `-detent compact|medium|large`, `-expanded YES`, `-gradient YES`

iPhone only: the iPad floating panel is not mocked.
