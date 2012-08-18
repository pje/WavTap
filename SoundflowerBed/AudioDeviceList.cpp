#include "AudioDeviceList.h"
#include "AudioDevice.h"

AudioDeviceList::AudioDeviceList(bool inputs) :
  mInputs(inputs)
{
  BuildList();
}

AudioDeviceList::~AudioDeviceList()
{
}

void  AudioDeviceList::BuildList()
{
  mDevices.clear();

  UInt32 propsize;

  verify_noerr(AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propsize, NULL));
  int nDevices = propsize / sizeof(AudioDeviceID);
  AudioDeviceID *devids = new AudioDeviceID[nDevices];
  verify_noerr(AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propsize, devids));

  for (int i = 0; i < nDevices; ++i) {
    AudioDevice dev(devids[i], mInputs);
    //if (dev.CountChannels() > 0)
    {
      Device d;

      d.mID = devids[i];
      dev.GetName(d.mName, sizeof(d.mName));
      mDevices.push_back(d);
    }
  }
  delete[] devids;
}
