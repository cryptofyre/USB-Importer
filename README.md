# USB-Importer
A tool/script designed to make transferring video files from your Drones/Cameras/etc easier.


## Configuration & Setup
To configure the properties for your device, you need to modify the `device_config.json` and `ImportUtility.ps1` files.

In the `device_config.json` file, you can specify the model of your device. This includes properties such as the device name currently. Make sure to update these properties according to your device's specifications for effective multi-device sorting.

In the `ImportUtility.ps1` file, you can customize the import process to cater to your device. This includes setting up the necessary file preferences, device specific pathing, and organizing the imported files in a way that suits your needs.

Additionally, if you want to customize the icon of the device you will need to find a PNG of your specified device (One supplied is of a DJI Avata 2), and convert it to a `.ico` and make sure the size is 256x256 then replace the `device.ico` on the device/folder.

After configuring the files/scripts, copy the files to your USB Drive / SD Card / Device for auto recognition, and try double-clicking the `autorun.bat` to have the copying and sorting take place.


### DISCLAIMER
I am not responsible for damage done to your own device, and you should always double check your work to make sure the proper things are being copied over.

