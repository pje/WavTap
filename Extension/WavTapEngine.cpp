#include "WavTapEngine.hpp"
#include <IOKit/audio/IOAudioControl.h>
#include <IOKit/audio/IOAudioLevelControl.h>
#include <IOKit/audio/IOAudioToggleControl.h>
#include <IOKit/audio/IOAudioDefines.h>
#include <IOKit/IOLib.h>
#include <IOKit/IOWorkLoop.h>
#include <IOKit/IOTimerEventSource.h>

#define INITIAL_SAMPLE_RATE  44100
#define BLOCK_SIZE 512
#define NUM_BLOCKS 32
#define NUM_STREAMS 1
#define super IOAudioEngine

OSDefineMetaClassAndStructors(WavTapEngine, IOAudioEngine)

bool WavTapEngine::init(OSDictionary *properties) {
  OSNumber *number = NULL;
  if (!super::init(properties)) {
    return false;
  }
  logTable[0] = 1.0E-4;
  logTable[1] = 1.09749875E-4;
  logTable[2] = 1.2045036E-4;
  logTable[3] = 1.3219411E-4;
  logTable[4] = 1.4508287E-4;
  logTable[5] = 1.5922828E-4;
  logTable[6] = 1.7475284E-4;
  logTable[7] = 1.9179103E-4;
  logTable[8] = 2.1049041E-4;
  logTable[9] = 2.3101296E-4;
  logTable[10] = 2.5353645E-4;
  logTable[11] = 2.7825593E-4;
  logTable[12] = 3.0538556E-4;
  logTable[13] = 3.3516026E-4;
  logTable[14] = 3.67838E-4;
  logTable[15] = 4.0370174E-4;
  logTable[16] = 4.4306213E-4;
  logTable[17] = 4.8626016E-4;
  logTable[18] = 5.336699E-4;
  logTable[19] = 5.857021E-4;
  logTable[20] = 6.4280734E-4;
  logTable[21] = 7.054802E-4;
  logTable[22] = 7.742637E-4;
  logTable[23] = 8.4975344E-4;
  logTable[24] = 9.326034E-4;
  logTable[25] = 0.0010235311;
  logTable[26] = 0.001123324;
  logTable[27] = 0.0012328468;
  logTable[28] = 0.0013530478;
  logTable[29] = 0.0014849682;
  logTable[30] = 0.0016297508;
  logTable[31] = 0.0017886495;
  logTable[32] = 0.0019630406;
  logTable[33] = 0.0021544348;
  logTable[34] = 0.0023644895;
  logTable[35] = 0.0025950242;
  logTable[36] = 0.002848036;
  logTable[37] = 0.0031257158;
  logTable[38] = 0.0034304692;
  logTable[39] = 0.0037649358;
  logTable[40] = 0.0041320124;
  logTable[41] = 0.0045348783;
  logTable[42] = 0.0049770237;
  logTable[43] = 0.005462277;
  logTable[44] = 0.0059948424;
  logTable[45] = 0.006579332;
  logTable[46] = 0.007220809;
  logTable[47] = 0.007924829;
  logTable[48] = 0.00869749;
  logTable[49] = 0.009545485;
  logTable[50] = 0.010476157;
  logTable[51] = 0.01149757;
  logTable[52] = 0.012618569;
  logTable[53] = 0.013848864;
  logTable[54] = 0.015199111;
  logTable[55] = 0.016681006;
  logTable[56] = 0.018307382;
  logTable[57] = 0.02009233;
  logTable[58] = 0.022051308;
  logTable[59] = 0.024201283;
  logTable[60] = 0.026560878;
  logTable[61] = 0.02915053;
  logTable[62] = 0.03199267;
  logTable[63] = 0.03511192;
  logTable[64] = 0.038535286;
  logTable[65] = 0.042292427;
  logTable[66] = 0.046415888;
  logTable[67] = 0.05094138;
  logTable[68] = 0.055908103;
  logTable[69] = 0.061359074;
  logTable[70] = 0.06734151;
  logTable[71] = 0.07390722;
  logTable[72] = 0.081113085;
  logTable[73] = 0.08902151;
  logTable[74] = 0.097701;
  logTable[75] = 0.10722672;
  logTable[76] = 0.1176812;
  logTable[77] = 0.12915497;
  logTable[78] = 0.14174742;
  logTable[79] = 0.15556762;
  logTable[80] = 0.17073527;
  logTable[81] = 0.18738174;
  logTable[82] = 0.20565122;
  logTable[83] = 0.22570197;
  logTable[84] = 0.24770764;
  logTable[85] = 0.2718588;
  logTable[86] = 0.29836473;
  logTable[87] = 0.32745492;
  logTable[88] = 0.35938138;
  logTable[89] = 0.3944206;
  logTable[90] = 0.43287614;
  logTable[91] = 0.47508103;
  logTable[92] = 0.5214008;
  logTable[93] = 0.5722368;
  logTable[94] = 0.62802917;
  logTable[95] = 0.6892612;
  logTable[96] = 0.75646335;
  logTable[97] = 0.83021754;
  logTable[98] = 0.91116273;
  logTable[99] = 1.0;
  number = OSDynamicCast(OSNumber, getProperty(NUM_BLOCKS_KEY));
  if (number) {
    numBlocks = number->unsigned32BitValue();
  } else {
    numBlocks = NUM_BLOCKS;
  }
  number = OSDynamicCast(OSNumber, getProperty(BLOCK_SIZE_KEY));
  if (number) {
    blockSize = number->unsigned32BitValue();
  } else {
    blockSize = BLOCK_SIZE;
  }
  outputStream = NULL;
  inputStream = NULL;
  duringHardwareInit = false;
  mLastValidSampleFrame = 0;
  return true;
}

bool WavTapEngine::initHardware(IOService *provider) {
  IOAudioSampleRate initialSampleRate;
  IOWorkLoop *wl;
  duringHardwareInit = true;
  if (!super::initHardware(provider)) {
    duringHardwareInit = false;
    return false;
  }
  initialSampleRate.whole = 0;
  initialSampleRate.fraction = 0;
  if (!createAudioStreams(&initialSampleRate)) {
    duringHardwareInit = false;
    return false;
  }
  if (initialSampleRate.whole == 0) {
    duringHardwareInit = false;
    return false;
  }
  blockTimeoutNS = blockSize;
  blockTimeoutNS *= 1000000000;
  blockTimeoutNS /= initialSampleRate.whole;
  setSampleRate(&initialSampleRate);
  setNumSampleFramesPerBuffer(blockSize * numBlocks);
  wl = getWorkLoop();
  if (!wl) {
    duringHardwareInit = false;
    return false;
  }
  timerEventSource = IOTimerEventSource::timerEventSource(this, ourTimerFired);
  if (!timerEventSource) {
    duringHardwareInit = false;
    return false;
  }
  workLoop->addEventSource(timerEventSource);
  duringHardwareInit = false;
  return true;
}

bool WavTapEngine::createAudioStreams(IOAudioSampleRate *initialSampleRate) {
  bool result = false;
  OSNumber *number = NULL;
  UInt32 numStreams;
  UInt32 streamNum;
  OSArray *formatArray = NULL;
  OSArray *sampleRateArray = NULL;
  UInt32 startingChannelID = 1;
  OSString *desc;
  desc = OSDynamicCast(OSString, getProperty(DESCRIPTION_KEY));
  if (desc) {
    setDescription(desc->getCStringNoCopy());
  }
  number = OSDynamicCast(OSNumber, getProperty(NUM_STREAMS_KEY));
  if (number) {
    numStreams = number->unsigned32BitValue();
  } else {
    numStreams = NUM_STREAMS;
  }
  formatArray = OSDynamicCast(OSArray, getProperty(FORMATS_KEY));
  if (formatArray == NULL) {
    IOLog("SF formatArray is NULL\n");
    goto Done;
  }
  sampleRateArray = OSDynamicCast(OSArray, getProperty(SAMPLE_RATES_KEY));
  if (sampleRateArray == NULL) {
    IOLog("SF sampleRateArray is NULL\n");
    goto Done;
  }
  for (streamNum = 0; streamNum < numStreams; streamNum++) {
    UInt32 maxBitWidth = 0;
    UInt32 maxNumChannels = 0;
    OSCollectionIterator *formatIterator = NULL;
    OSCollectionIterator *sampleRateIterator = NULL;
    OSDictionary *formatDict;
    IOAudioSampleRate sampleRate;
    IOAudioStreamFormat initialFormat;
    bool initialFormatSet;
    UInt32 channelID;
    char outputStreamName[64];
    char inputStreamName[64];
    initialFormatSet = false;
    sampleRate.whole = 0;
    sampleRate.fraction = 0;
    inputStream = new IOAudioStream;
    if (inputStream == NULL) {
      IOLog("SF could not create new input IOAudioStream\n");
      goto Error;
    }
    outputStream = new IOAudioStream;
    if (outputStream == NULL) {
      IOLog("SF could not create new output IOAudioStream\n");
      goto Error;
    }
    snprintf(inputStreamName, 64, "WavTap Input Stream #%u", (unsigned int)streamNum + 1);
    snprintf(outputStreamName, 64, "WavTap Output Stream #%u", (unsigned int)streamNum + 1);
    if (!inputStream->initWithAudioEngine(this, kIOAudioStreamDirectionInput, startingChannelID, inputStreamName) || !outputStream->initWithAudioEngine(this, kIOAudioStreamDirectionOutput, startingChannelID, outputStreamName)) {
      IOLog("SF could not init one of the streams with audio engine. \n");
      goto Error;
    }
    formatIterator = OSCollectionIterator::withCollection(formatArray);
    if (!formatIterator) {
      IOLog("SF NULL formatIterator\n");
      goto Error;
    }
    sampleRateIterator = OSCollectionIterator::withCollection(sampleRateArray);
    if (!sampleRateIterator) {
      IOLog("SF NULL sampleRateIterator\n");
      goto Error;
    }
    formatIterator->reset();
    while ((formatDict = (OSDictionary *)formatIterator->getNextObject())) {
      IOAudioStreamFormat format;
      if (OSDynamicCast(OSDictionary, formatDict) == NULL) {
        IOLog("SF error casting formatDict\n");
        goto Error;
      }
      if (IOAudioStream::createFormatFromDictionary(formatDict, &format) == NULL) {
        IOLog("SF error in createFormatFromDictionary()\n");
        goto Error;
      }
      if (!initialFormatSet) {
        initialFormat = format;
      }
      sampleRateIterator->reset();
      while ((number = (OSNumber *)sampleRateIterator->getNextObject())) {
        if (!OSDynamicCast(OSNumber, number)) {
          IOLog("SF error iterating sample rates\n");
          goto Error;
        }
        sampleRate.whole = number->unsigned32BitValue();
        inputStream->addAvailableFormat(&format, &sampleRate, &sampleRate);
        outputStream->addAvailableFormat(&format, &sampleRate, &sampleRate);
        if (format.fNumChannels > maxNumChannels) {
          maxNumChannels = format.fNumChannels;
        }
        if (format.fBitWidth > maxBitWidth) {
          maxBitWidth = format.fBitWidth;
         }
        if (initialSampleRate->whole == 0) {
          initialSampleRate->whole = sampleRate.whole;
        }
      }
    }
    mBufferSize = blockSize * numBlocks * maxNumChannels * maxBitWidth / 8;
    if (mBuffer == NULL) {
      mBuffer = (void *)IOMalloc(mBufferSize);
      if (!mBuffer) {
        IOLog("WavTap: Error allocating output buffer - %lu bytes.\n", (unsigned long)mBufferSize);
        goto Error;
      }
      mThruBuffer = (float*)IOMalloc(mBufferSize);
      if (!mThruBuffer) {
        IOLog("WavTap: Error allocating thru buffer - %lu bytes.\n", (unsigned long)mBufferSize);
        goto Error;
      }
      memset((UInt8*)mThruBuffer, 0, mBufferSize);
    }
    inputStream->setFormat(&initialFormat);
    inputStream->setSampleBuffer(mBuffer, mBufferSize);
    addAudioStream(inputStream);
    inputStream->release();
    outputStream->setFormat(&initialFormat);
    outputStream->setSampleBuffer(mBuffer, mBufferSize);
    addAudioStream(outputStream);
    outputStream->release();
    formatIterator->release();
    sampleRateIterator->release();
    for (channelID = startingChannelID; channelID < (startingChannelID + maxNumChannels); channelID++) {
      char channelName[20];
      snprintf(channelName, 20, "Channel %u", (unsigned int)channelID);
    }
    startingChannelID += maxNumChannels;
    continue;
Error:
    IOLog("WavTapEngine[%p]::createAudioStreams() - ERROR\n", this);
    if (inputStream) {
      inputStream->release();
    }
    if (outputStream) {
      outputStream->release();
    }
    if (formatIterator) {
      formatIterator->release();
    }
    if (sampleRateIterator) {
      sampleRateIterator->release();
    }
    goto Done;
  }
  result = true;
Done:
  if (!result) {
    IOLog("WavTapEngine[%p]::createAudioStreams() - failed!\n", this);
  }
  return result;
}

void WavTapEngine::free() {
  if (mBuffer) {
    IOFree(mBuffer, mBufferSize);
    mBuffer = NULL;
  }
  if (mThruBuffer) {
    IOFree(mThruBuffer, mBufferSize);
    mThruBuffer = NULL;
  }
  super::free();
}

IOReturn WavTapEngine::performAudioEngineStart() {
  takeTimeStamp(false);
  currentBlock = 0;
  timerEventSource->setTimeout(blockTimeoutNS);
  uint64_t time;
  clock_get_uptime(&time);
  absolutetime_to_nanoseconds(time, &nextTime);
  nextTime += blockTimeoutNS;
  return kIOReturnSuccess;
}

IOReturn WavTapEngine::performAudioEngineStop() {
  timerEventSource->cancelTimeout();
  return kIOReturnSuccess;
}

UInt32 WavTapEngine::getCurrentSampleFrame() {
  return currentBlock * blockSize;
}

IOReturn WavTapEngine::performFormatChange(IOAudioStream *audioStream, const IOAudioStreamFormat *newFormat, const IOAudioSampleRate *newSampleRate) {
  if (newSampleRate && !duringHardwareInit) {
    UInt64 newblockTime = blockSize;
    newblockTime *= 1000000000;
    blockTimeoutNS = newblockTime / newSampleRate->whole;
  }
  return kIOReturnSuccess;
}

void WavTapEngine::ourTimerFired(OSObject *target, IOTimerEventSource *sender) {
  if (target) {
    WavTapEngine *audioEngine = OSDynamicCast(WavTapEngine, target);
    UInt64 thisTimeNS;
    uint64_t time;
    SInt64 diff;
    if (audioEngine) {
      IOAudioStream *outStream = audioEngine->getAudioStream(kIOAudioStreamDirectionOutput, 1);
      if (outStream->numClients == 0) {
        memset((UInt8*)audioEngine->mThruBuffer, 0, audioEngine->mBufferSize);
      }
      audioEngine->currentBlock++;
      if (audioEngine->currentBlock >= audioEngine->numBlocks) {
        audioEngine->currentBlock = 0;
        audioEngine->takeTimeStamp();
      }
      clock_get_uptime(&time);
      absolutetime_to_nanoseconds(time, &thisTimeNS);
      diff = ((SInt64)audioEngine->nextTime - (SInt64)thisTimeNS);
      sender->setTimeout(audioEngine->blockTimeoutNS + diff);
      audioEngine->nextTime += audioEngine->blockTimeoutNS;
    }
  }
}

IOReturn WavTapEngine::clipOutputSamples(const void *mixBuf, void *sampleBuf, UInt32 firstSampleFrame, UInt32 numSampleFrames, const IOAudioStreamFormat *streamFormat, IOAudioStream *audioStream) {
  UInt32 channelCount = streamFormat->fNumChannels;
  UInt32 offset = firstSampleFrame * channelCount;
  UInt32 byteOffset = offset * sizeof(float);
  UInt32 numBytes = numSampleFrames * channelCount * sizeof(float);
  WavTapDevice *device = (WavTapDevice*)audioDevice;
  mLastValidSampleFrame = firstSampleFrame+numSampleFrames;
  if (device->mMuteIn[0]) {
    memset((UInt8*)mThruBuffer + byteOffset, 0, numBytes);
  } else {
    memcpy((UInt8*)mThruBuffer + byteOffset, (UInt8 *)mixBuf + byteOffset, numBytes);
    float masterGain = logTable[ device->mGain[0] ];
    float masterVolume = logTable[ device->mVolume[0] ];
    for (UInt32 channel = 0; channel < channelCount; channel++) {
      SInt32 channelMute = device->mMuteIn[channel+1];
      float channelGain = logTable[ device->mGain[channel+1] ];
      float channelVolume = logTable[ device->mVolume[channel+1] ];
      float adjustment = masterVolume * channelVolume * masterGain * channelGain;
      for (UInt32 channelBufferIterator = 0; channelBufferIterator < numSampleFrames; channelBufferIterator++) {
        if (channelMute){
          mThruBuffer[offset + channelBufferIterator*channelCount + channel] = 0;
        } else {
          mThruBuffer[offset + channelBufferIterator*channelCount + channel] *= adjustment;
        }
      }
    }
  }
  return kIOReturnSuccess;
}

IOReturn WavTapEngine::convertInputSamples(const void *sampleBuf, void *destBuf, UInt32 firstSampleFrame, UInt32 numSampleFrames, const IOAudioStreamFormat *streamFormat, IOAudioStream *audioStream) {
  UInt32 frameSize = streamFormat->fNumChannels * sizeof(float);
  UInt32 offset = firstSampleFrame * frameSize;
  WavTapDevice *device = (WavTapDevice*)audioDevice;
  if (device->mMuteOut[0]) {
    memset((UInt8*)destBuf, 0, numSampleFrames * frameSize);
  } else {
    memcpy((UInt8*)destBuf, (UInt8*)mThruBuffer + offset, numSampleFrames * frameSize);
  }
  return kIOReturnSuccess;
}
