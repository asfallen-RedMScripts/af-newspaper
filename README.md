# Newspaper System for RedM [RSG-CORE]

## Overview
The OutWest Newspaper System is a comprehensive in-game newspaper management system designed for RedM servers. It allows players to read newspapers, view dynamic stories, and—if they are assigned the reporter role—publish new articles. The system integrates with `rsg-core` and uses a MySQL database (via `oxmysql`) to manage newspaper data, including versioning and unique item identification.

## Features
- **In-Game Newspaper Item:** Players can use a newspaper item to open the interactive NUI interface.
- **Dynamic Content Loading:** Newspaper stories are fetched from the database and displayed in a NUI (HTML/CSS/JS) interface.
- **Reporter Panel:** Only players with the reporter job can access a dedicated panel to publish new stories.
- **Automatic Versioning:** Each new story or newspaper purchase automatically increments the newspaper version.
- **Copy Functionality:** Players can duplicate newspaper items (subject to inventory weight constraints) for convenience.
- **Database Integration:** Uses MySQL (`oxmysql`) to store and manage newspaper records and their lookup data.
- **User Notifications:** Provides in-game alerts and notifications using `ox_lib:notify` for better user experience.

## Installation
1. **Download the Resource:**
   - Clone or download the OutWest Newspaper System resource and place it in your RedM server's resource directory.

2. **Dependencies:**
   - Ensure that you have the following dependencies installed and properly configured:
     - `rsg-core`
     - `oxmysql`
     - `ox_lib`

3. **Resource Configuration:**
   - Verify that the `fxmanifest.lua` file is configured correctly:
     - **Game:** RedM (`game 'rdr3'`)
     - **FX Version:** `cerulean`
     - **Lua Version:** Lua 5.4
     - **UI Page:** The NUI interface is defined in `nui/index.html` along with its assets (`style.css`, `script.js`, and images).

4. **Database Setup:**
   - Create and configure the required MySQL tables (`newspaper` and `newspaper_lookup`) as referenced in the scripts.
   - Ensure that your database connection settings are correctly set up for `oxmysql` to function.

## Configuration
- **Debug Mode:**
  - Enable or disable debug messages by editing `Config.Debug` in `config.lua` (set to `true` for debugging or `false` for production).

- **UI Customization:**
  - Modify the files in the `nui` folder (HTML, CSS, and JavaScript) to tailor the appearance and behavior of the newspaper interface.

## Usage
- **Opening a Newspaper:**
  - Use the newspaper item from your inventory to trigger the NUI interface, which will display the latest newspaper stories fetched from the database.

- **Reporter Panel:**
  - If your character’s job is set to `reporter`, you can open the reporter panel using the `/reporterpanel` command. This panel allows you to publish new stories.

- **Purchasing a Newspaper:**
  - Players can purchase a newspaper, which creates a new version of the newspaper record, assigns a unique ID, and adds the item to their inventory.

- **Copying a Newspaper:**
  - Use the copy functionality within the NUI to duplicate a newspaper item. The system checks for sufficient inventory space before performing the copy.

## Video Demonstration
For a detailed walkthrough of the system, check out the video demonstration below:

 https://github.com/user-attachments/assets/9c06f268-6a8a-42df-ae68-85c6fa7faf24





## Credits
- **Author:** afoolasfallen

## License
This project is licensed under the terms specified in the LICENSE file. Please refer to that file for more information.
