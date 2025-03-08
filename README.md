# AP-Doku
A full-featured Sudoku game built with SwiftUI, featuring Archipelago Multi-World integration.  Now you can get hints for your games while BK'd from your phone!
<p align="center"> <img src="https://github.com/user-attachments/assets/67a69f25-9ad3-46e8-9558-13681951c6ee" alt="AP Doku Home Screen" width="300"> </p>


## Features
- AP Integration!
- 4 difficulty levels, including "Killer" mode, which takes the difficulty of Hard mode and adds cages around number cells to show their end number totals.
- Hints are granted for your entered slot based on the difficulty of the puzzle you selected.
- Simple design, in line with the AP logo colors.
- Alerts telling you what hints you are getting for your connected slot.
- An alert to tell you if your game no longer has any more hints.
- Hint caching, so if you are disconnected when playing, it will send the hints when you reconnect. (Not much testing has been done with this, but it should work)


## Installing the IPA
Possibly available soon on the App Store!


But for now:

Download the IPA in the releases tab, and install using your preferred side-loading method. Be warned, without an Apple Developer license, you will have to re-sign the application every 7 days to keep it working.


## Building the app
1. Clone the Repository:
   ```bash
    git clone https://github.com/AlexMKramer/AP-Doku.git

2. Open the Project in Xcode:
    - Open AP Doku.xcodeproj in Xcode.
    - Make sure you’re running Xcode 12 or later.
3. Run the App:
    - Build and run on the simulator or an actual device.
    - Select a difficulty level and start solving puzzles!

## Contributions:
This is based on a fork of https://github.com/jaredcassoutt/sudoku_swiftui.  I have changed UI elements, changed some of the puzzle logic, removed a some unneeded features for this deployment, and added the AP integration.  Without the linked repo, this project would have had no base, so thank you to the author!


Feel free to fork the project, submit issues, or suggest improvements. Feedback and ideas for new features are welcome!

## License

This project is open-source under the MIT License.

