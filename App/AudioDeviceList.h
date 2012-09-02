#ifndef __AudioDeviceList_h__
#define __AudioDeviceList_h__

#include <CoreServices/CoreServices.h>
#include <CoreAudio/CoreAudio.h>
#include <vector>

class AudioDeviceList {

public:
  struct Device {
    char mName[64];
    AudioDeviceID mID;
  };
  typedef std::vector<Device> DeviceList;
  AudioDeviceList();
  ~AudioDeviceList();
  DeviceList &GetList() { return mDevices; }

protected:
  void BuildList();
  void EraseList();
  DeviceList mDevices;
};

#endif // __AudioDeviceList_h__
