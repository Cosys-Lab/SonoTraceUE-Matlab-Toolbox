foundPath = sonotraceue.findSonoTraceUEToolboxFolder();
cd(char(foundPath.toAbsolutePath.toString));
open("Examples\example.m")