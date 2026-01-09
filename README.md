
<a id="TMP_18a0"></a>

# SonoTraceUE Matlab Toolbox

Matlab Toolbox servering as an interface client to interact with the Unreal Engine implementation of [SonoTraceUE](https://github.com/Cosys-Lab/SonoTraceUE).

<a id="H_4dd9"></a>

## Installation

Find the latest [release on Github](https://github.com/Cosys-Lab/SonoTraceUE-Matlab-Toolbox/releases) or the MathWorks File Exchange for the toolbox. You can also clone or download this repository and use it from source.

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
<a id="H_33ac"></a>

## General Usage
<a id="H_4320"></a>

All functions in this Toolbox exist within the `sonotraceue` namespace. For calling these functions you therefore have to add the namespace name to the beginning.


`output = sonotraceue.functionName(...)`

<a id="TMP_6e11"></a>

## Open\-Source Libraries Credits
-  [Logger](https://github.com/ismet55555/Logging-For-MATLAB) For MATLAB by Ismet Handžić 
-  [Progress bar](https://www.mathworks.com/matlabcentral/fileexchange/121363-progress-bar-cli-gui-parfor?s_tid=srchtitle) by HyunGwang Cho 
<a id="TMP_7eaa"></a>

## License

This project is released under the CC\-BY\-NC\-SA\-4.0 license.

