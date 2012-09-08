#include "AudioDeviceList.h"
#include "AudioDevice.h"

AudioDeviceList::AudioDeviceList() {
  BuildList();
}

AudioDeviceList::~AudioDeviceList() {
}

void  AudioDeviceList::BuildList() {
  OSStatus err = noErr;
  mDevices.clear();
  UInt32 propsize;
  AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyDevices, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
  err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &theAddress, 0, NULL,&propsize);
  int audioDeviceIDSize = sizeof(AudioDeviceID);
  int nDevices = propsize / audioDeviceIDSize;
  AudioDeviceID *devids = (AudioDeviceID *)calloc(nDevices, sizeof(AudioDeviceID));
  err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &theAddress, 0, NULL, &propsize, devids);
  for (int i = 0; i < nDevices; ++i) {
    int mInputs = 2;
    AudioDevice dev(devids[i], mInputs);
    {
      Device d;
      d.mID = devids[i];
      dev.GetName(d.mName, sizeof(d.mName));
      mDevices.push_back(d);
    }
  }
  delete[] devids;
}
