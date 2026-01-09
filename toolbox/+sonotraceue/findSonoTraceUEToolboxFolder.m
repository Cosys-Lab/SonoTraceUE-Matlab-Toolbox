function foundPath = findSonoTraceUEToolboxFolder()
    tbxlist = com.mathworks.addons_toolbox.ToolboxManagerForAddOns().getInstalled();
    idx = arrayfun(@(x)startsWith(x.getName(),'SonoTraceUE Toolbox'),tbxlist);
    foundPath = tbxlist(idx).getInstalledFolder();
end