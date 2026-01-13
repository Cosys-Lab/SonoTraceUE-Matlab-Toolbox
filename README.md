
<a id="TMP_18a0"></a>

# SonoTraceUE Matlab Toolbox

Matlab Toolbox servering as an interface client to interact with the Unreal Engine implementation of [SonoTraceUE](https://github.com/Cosys-Lab/SonoTraceUE).

<a id="H_4dd9"></a>

## Installation

Find the latest [release on Github](https://github.com/Cosys-Lab/SonoTraceUE-Matlab-Toolbox/releases) or the [MathWorks File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/183020-sonotraceue-matlab-toolbox) for the toolbox. You can also clone or download this repository and use it from source.

<a id="TMP_3c79"></a>

## Dependencies
-  Unreal Engine with [SonoTraceUE Plugin](https://github.com/Cosys-Lab/SonoTraceUE) v1.0 
-  Instrument Control Toolbox 
-  Phased Array System Toolbox 
-  Signal Processing Toolbox 
-  Computer Vision Toolbox 
-  Lidar Toolbox 
-  Navigation Toolbox 
-  Radar Toolbox 
-  Robotics System Toolbox 
-  ROS Toolbox 
-  Satellite Communications Toolbox 
-  Sensor Fusion and Tracking Toolbox 
<a id="TMP_2c8c"></a>

## Example

An example is available, to quickly open this file after installing the toolbox, run the following command or find it manually in the `examples` folder.

```matlab
sonotraceue.openExample
```

This example works best with the *Default* level of the SonoTraceUE sample project.

<a id="H_33ac"></a>

## General Usage
<a id="TMP_6d63"></a>

### Namespace
<a id="H_4320"></a>

All functions in this Toolbox exist within the `sonotraceue` namespace. For calling these functions you therefore have to add the namespace name to the beginning.


`output = sonotraceue.functionName(...)`

<a id="TMP_0152"></a>

### Coordinate System Convention

**Important:** This MATLAB client uses a **right\-handed coordinate system with meters** as the unit of measurement, which follows MATLAB's convention. This is **very different** from Unreal Engine's coordinate system.


**MATLAB/Client Coordinate System:**

-  Right\-handed coordinate system 
-  **X**: Forward 
-  **Y**: Right 
-  **Z**: Up 
-  Units: **Meters** 

**Unreal Engine Coordinate System:**

-  Left\-handed Z\-up coordinate system 
-  Units: **Centimeters** 

The toolbox automatically handles coordinate transformations between these two systems. When you send data to or receive data from the SonoTraceUE plugin, the conversions are performed transparently using the `matlabTFormToUnreal()` and `unrealToMatlabTForm()` helper functions.

<a id="TMP_4358"></a>

## API Reference
<a id="TMP_0b9d"></a>

### Connection and Interface Management
<a id="TMP_6c25"></a>

#### `Interface` Class

The main interface class that establishes and manages the TCP connection to the SonoTraceUE plugin.


**Constructor:**

```matlab
interface = sonotraceue.Interface(serverIP, serverPort, sendInputSettings, logLevel) 
```

**Parameters:**

-  `serverIP` (string, optional): IP address of the server. Default: `'localhost'` 
-  `serverPort` (int, optional): Port number. Default: `9098` 
-  `sendInputSettings` (bool, optional): Whether to send input settings to UE. Default: `false` 
-  `logLevel` (string, optional): Logging level ('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL') 

**Example:**

```matlab
% Connect to local SonoTraceUE instance
interface = sonotraceue.Interface('localhost', 9098, false, 'INFO'); 
```
<a id="TMP_7a85"></a>
<a id="TMP_28b0"></a>

### Settings and Configuration
<a id="TMP_3590"></a>

#### `receiveSettings()`

Receives simulation settings from the Unreal Engine plugin. This includes all emitter/receiver configurations, simulation parameters, object settings, frequencies, and emitter signals.

```matlab
settings = interface.receiveSettings() 
```

**Returns:**

-  `settings`: A `sonotraceue.Settings` object containing all simulation configuration 

The `Settings` object contains properties such as:

-  Emitter and receiver positions 
-  Simulation parameters (frequency range, sample rate, speed of sound) 
-  Ray tracing settings (number of rays, maximum bounces, ray distance) 
-  Component calculation flags (specular, diffraction, direct path) 
-  Sensor limits (azimuth and elevation angles) 
-  Object acoustic properties 
<a id="TMP_15ea"></a>
<a id="TMP_4c60"></a>

### Triggering Measurements
<a id="TMP_79c9"></a>

#### `triggerMeasurement()`

Triggers a new acoustic measurement in the Unreal Engine simulation.

```matlab
success = interface.triggerMeasurement() 
success = interface.triggerMeasurement(overrideEmitterSignalIndexes) 
```

**Parameters:**

-  `overrideEmitterSignalIndexes` (array, optional): Array of emitter signal indexes to override the default configuration 

**Returns:**

-  `success`: Boolean indicating whether the trigger was successful 

**Example:**

```matlab
% Trigger with default settings
triggered = interface.triggerMeasurement();
% Trigger with specific emitter signal indexes
triggered = interface.triggerMeasurement([0, 1, 0, 1]); 
```
<a id="TMP_60c5"></a>
<a id="TMP_3ada"></a>

### Emitter Signal Control
<a id="TMP_5831"></a>

#### `SetCurrentEmitterSignalIndexForSpecificEmitter()`

Sets the emitter signal index for a specific emitter.

```matlab
success = interface.SetCurrentEmitterSignalIndexForSpecificEmitter(emitterIndex, emitterSignalIndex) 
```

**Parameters:**

-  `emitterIndex`: Index of the emitter (0\-based) 
-  `emitterSignalIndex`: Index of the signal to use 
<a id="TMP_4d26"></a>
<a id="TMP_2ecf"></a>

#### `SetCurrentEmitterSignalIndexes()`

Sets the emitter signal indexes for all emitters at once.

```matlab
success = interface.SetCurrentEmitterSignalIndexes(emitterSignalIndexes) 
```

**Parameters:**

-  `emitterSignalIndexes`: Array of signal indexes for all emitters 

<a id="TMP_6249"></a>

#### `GetCurrentEmitterSignalIndexForSpecificEmitter()`

Retrieves the current emitter signal index for a specific emitter.

```matlab
index = interface.GetCurrentEmitterSignalIndexForSpecificEmitter(emitterIndex)
```
<a id="TMP_736f"></a>
<a id="TMP_0a5f"></a>

#### `GetCurrentEmitterSignalIndexes()`

Retrieves the current emitter signal indexes for all emitters.

```matlab
indexes = interface.GetCurrentEmitterSignalIndexes() 
```
<a id="TMP_599f"></a>
<a id="TMP_802d"></a>

### Transform Control
<a id="TMP_3e5b"></a>

#### `setNewSensorRelativeTransform()`

Sets a new relative transform for the sensor (relative to its owner/parent).

```matlab
success = interface.setNewSensorRelativeTransform(tform) 
```

**Parameters:**

-  `tform`: 4x4 homogeneous transformation matrix (MATLAB convention) 
<a id="TMP_7c6d"></a>
<a id="TMP_75d8"></a>

#### `setNewSensorWorldTransform()`

Sets a new world transform for the sensor in absolute coordinates.

```matlab
success = interface.setNewSensorWorldTransform(tform)
success = interface.setNewSensorWorldTransform(tform, teleport) 
```

**Parameters:**

-  `tform`: 4x4 homogeneous transformation matrix (MATLAB convention) 
-  `teleport` (bool, optional): If true, instantly teleports; if false, performs smooth movement. Default: `false` 
<a id="TMP_1b13"></a>
<a id="TMP_0c4a"></a>

#### `setNewSensorOwnerWorldTransform()`

Sets a new world transform for the sensor's owner/parent actor.

```matlab
success = interface.setNewSensorOwnerWorldTransform(tform)
success = interface.setNewSensorOwnerWorldTransform(tform, teleport) 
```

**Parameters:**

-  `tform`: 4x4 homogeneous transformation matrix (MATLAB convention) 
-  `teleport` (bool, optional): If true, instantly teleports; if false, performs smooth movement. Default: `false` 

<a id="TMP_49a3"></a>

#### `setNewEmitterPositions()`

Updates the positions of specific emitters.

```matlab
success = interface.setNewEmitterPositions(emitterIndexes, NewEmitterPositions, relativeTransform, reApplyOffset) 
```

**Parameters:**

-  `emitterIndexes`: Array of emitter indexes to update 
-  `NewEmitterPositions`: 3×N matrix of positions in meters (MATLAB convention) 
-  `relativeTransform` (bool): If true, positions are relative to sensor frame 
-  `reApplyOffset` (bool): If true, applies the configured emitter offset 

<a id="TMP_8660"></a>

#### `setNewReceiverPositions()`

Updates the positions of specific receivers.

```matlab
success = interface.setNewReceiverPositions(receiverIndexes, NewReceiverPositions, relativeTransform, reApplyOffset) 
```

**Parameters:**

-  `receiverIndexes`: Array of receiver indexes to update 
-  `NewReceiverPositions`: 3×N matrix of positions in meters (MATLAB convention) 
-  `relativeTransform` (bool): If true, positions are relative to sensor frame 
-  `reApplyOffset` (bool): If true, applies the configured receiver offset 

<a id="TMP_4655"></a>

### Data Communication
<a id="TMP_6980"></a>

#### `SendDataMessage()`

Sends a generic data message to the Unreal Engine plugin. This allows custom data exchange between MATLAB and UE.

```matlab
success = interface.SendDataMessage(dataMessage) 
```

**Parameters:**

-  `dataMessage`: A `sonotraceue.DataMessage` object 

**DataMessage Constructor:**

```matlab
msg = sonotraceue.DataMessage(type, order, strings, integers, floats) 
```

**Parameters:**

-  `type` (int): Custom message type identifier 
-  `order` (array): Array specifying data order (0=string, 1=integer, 2=float) 
-  `strings` (cell array): Cell array of strings 
-  `integers` (array): Array of integer values 
-  `floats` (array): Array of float values 

**Example:**

```matlab
% Create a data message with mixed types
msg = sonotraceue.DataMessage(1, [0, 1, 2], {'hello'}, [42], [3.14]); 
success = interface.SendDataMessage(msg); 
```

<a id="TMP_9185"></a>

#### `receiveData()`

Receives data from the Unreal Engine plugin. This can be measurement data or custom data messages.

```matlab
[data, type] = interface.receiveData() 
```

**Returns:**

-  `data`: Either a `Measurement` object (type=1) or `DataMessage` object (type=2) 
-  `type`: Integer indicating data type: 
-  `1`: Measurement data 
-  `2`: Data message 
-  `0`: End of connection 
-  `-1`: No active interface 
-  `-2`: Unknown message 
<a id="TMP_9c0a"></a>
<a id="TMP_2f77"></a>

### `Measurement` Class

Contains all data from a single acoustic measurement, including ray\-traced points, impulse responses, and sensor poses.


**Key Properties:**

-  `index`: Measurement index number 
-  `timestamp`: Measurement timestamp 
-  `emitterTForms`: 4×4×N array of emitter transforms 
-  `receiverTForms`: 4×4×M array of receiver transforms 
-  `sensorTForm`: 4×4 sensor world transform 
-  `reflectedPoints`: Struct Array of ray\-traced point structures, explained below 
-  `directPathLOS`: Line\-of\-sight results for direct path 
-  `impulseResponses`: Generated impulse responses (emitters × receivers × samples) 
-  `receiverSignals`: Generated receiver signals (receivers × samples) 
-  `specularSubOutput`: Specular reflection component results 
-  `dsiffractionSubOutput`: Diffraction component results 
-  `directPathSubOutput`: Direct path component results 
<a id="TMP_1aa8"></a>

#### `reflectedPoints` Structure 

The  `reflectedPoints` struct array of the `Measurement` class holds the important data on all the reflected simulation points. This table explains all the fields of this array.

<a id="TMP_0676"></a>

## Field Summary Table
| **Field**  | **Type**  | **Description**   |
| :-- | :-- | :-- |
| `location`  | `[3×1 double]`  | 3D position of point (converted from cm to meters, Y\-axis inverted)   |
| `reflectionDirection`  | `[3×1 double]`  | Direction of acoustic reflection (Y\-axis inverted)   |
| `label`  | `string`  | Object label (from component name)   |
| `index`  | `int32`  | Sequential point index   |
| `summedStrength`  | `float`  | Total strength across all frequencies   |
| `strengths`  | `[Em × Rx × Freq float]`  | Strength values per emitter, receiver, and frequency   |
| `totalDistance`  | `float`  | Total acoustic path length (converted from cm to meters)   |
| `totalDistancesFromEmitters`  | `[Em × 1 float]`  | Path length per emitter (converted from cm to meters)   |
| `totalDistanceToReceivers`  | `[Em × Rx float]`  | Path length from this point to each receiver, per emitter (converted from cm to meters)   |
| `distanceToSensor`  | `float`  | Direct distance to sensor (converted from cm to meters)   |
| `objectTypeIndex`  | `int32`  | Index into ObjectSettings array   |
| `isHit`  | `logical`  | `true` if ray hit geometry   |
| `isLastHit`  | `logical`  | `true` if final bounce in ray path   |
| `curvatureMagnitude`  | `float`  | Surface curvature at hit point   |
| `isSpecular`  | `logical`  | `true` if from specular component   |
| `isDiffraction`  | `logical`  | `true` if from diffraction component   |
| `isDirectPath`  | `logical`  | `true` if from direct path component   |
| `rayIndex`  | `int32`  | The original index of the raytracing resulting in this point   |
| `bounceIndex`  | `int32`  | The bounce index of the multi\-path reflections of the rays   |
| `emitterDirectivities`  | `[Em × 1 float]`  | The calculated source directivity for each emitter to the first reflection   |


Em = Number of Emitters, Rx = Number of Receivers, Freq = Number of Frequencies

<a id="TMP_4768"></a>

### `Measurement` **Methods:**
<a id="TMP_69ad"></a>

#### `synthetizeIRFromPoints()`

Synthesizes impulse responses from the reflected points data.

```matlab
measurement = measurement.synthetizeIRFromPoints(settings, NumberOfSamplesIRFilter, ...
                                                 IRFilterGaussAlpha, NumberOfIRSamples, ...
                                                 ApproximateIRCutDB, EnableApproximateIR, EnablepatternSum) 
```
<a id="TMP_83ef"></a>
<a id="TMP_71d0"></a>

#### `receiverSignalGenerationFromIR()`

Generates receiver signals by convolving impulse responses with emitter signals.


`measurement = measurement.receiverSignalGenerationFromIR(settings)`

<a id="TMP_96d8"></a>

### Helper Functions
<a id="TMP_627e"></a>

#### `unrealToMatlabTForm()`

Converts Unreal Engine position and rotation to a MATLAB transformation matrix.

```matlab
tform = sonotraceue.unrealToMatlabTForm(position, rotation)
```

<a id="TMP_3179"></a>

#### `matlabTFormToUnreal()`

Converts a MATLAB transformation matrix to Unreal Engine position and rotation.

```matlab
[locationCentimeters, rotationQuat] = sonotraceue.matlabTFormToUnreal(tform) 
```
<a id="TMP_1e97"></a>

## Typical Workflow

Here's a typical workflow for using the SonoTraceUE MATLAB client:

```matlab
% 1. Establish connection
interface = sonotraceue.Interface('localhost', 9099, false, 'INFO');

% 2. Receive initial settings
settings = interface.receiveSettings();

% 3. (Optional) Update sensor position
tform = eye(4);
tform(1:3, 4) = [1.0; 0.5; 0.2]; % X, Y, Z in meters
interface.setNewSensorWorldTransform(tform, true);

% 4. Trigger measurement
triggered = interface.triggerMeasurement();

% 5. Receive measurement data
[measurement, dataType] = interface.receiveData();

% 6. Process measurement
if dataType == 1
    % Synthesize impulse responses
    measurement = measurement.synthetizeIRFromPoints(settings, 128, 3.0, 4096, -60, false, false);
    
    % Generate receiver signals
    measurement = measurement.receiverSignalGenerationFromIR(settings);
    
    % Access results
    signals = measurement.receiverSignals;
end
```
<a id="TMP_6e11"></a>

## Open\-Source Libraries Credits
-  [Logger](https://github.com/ismet55555/Logging-For-MATLAB) For MATLAB by Ismet Handžić 
-  [Progress bar](https://www.mathworks.com/matlabcentral/fileexchange/121363-progress-bar-cli-gui-parfor?s_tid=srchtitle) by HyunGwang Cho 
<a id="TMP_7eaa"></a>

## License

This project is released under the CC\-BY\-NC\-SA\-4.0 license.

