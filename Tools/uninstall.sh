set -e

sudo rm -rf /System/Library/Extensions/Soundflower.kext
sudo rm -rf /Library/Receipts/Soundflower*
sudo rm -rf /var/db/receipts/com.cycling74.soundflower.*
sudo rm -rf /Applications/Soundflower

echo "Done!"
