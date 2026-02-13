# TODO

- [x] Improve performance of image loading: currently images load asynchronously but the loading is slow (scrolling fast will result in a lot of spinners for instance)
- [x] TokenStore uses a lot of deprecated stuff, replace that with newer APIs
- [x] Remove the locate circle feature on CircleDetail view
- [x] Fix the bug where tapping on the MapPopover does not correctly open the CircleDetail view in the bottom panel sheet
- [x] Use the official SearchBar component (together with the separate search view as a best practice) for the search bar in the Catalog view, and expand the bottom sheet to fullscreen when in the search result view