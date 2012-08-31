#include "AudioDeviceList.h"
#include "AudioDevice.h"

AudioDeviceList::AudioDeviceList() { BuildList(); }
AudioDeviceList::~AudioDeviceList() {}
void  AudioDeviceList::BuildList()
{
  mDevices.clear();
  UInt32 propsize;
  verify_noerr(AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propsize, NULL));
  int nDevices = propsize / sizeof(AudioDeviceID);
  AudioDeviceID *devids = new AudioDeviceID[nDevices];
  verify_noerr(AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propsize, devids));

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
