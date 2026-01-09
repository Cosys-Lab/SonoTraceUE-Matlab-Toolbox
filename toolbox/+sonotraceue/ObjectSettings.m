classdef ObjectSettings

    properties
        name = "UNKNOWN";
        uniqueIndex = 0;
        isStaticMesh = true;
        isSkeletalMesh = false;
        resourcePath = "";
        description = "";
        drawDebugFirstOccurrence = false;
        brdfTransitionPosition = 0;
        brdfTransitionSlope = 0;
        brdfExponentsSpecular = [];
        brdfExponentsDiffraction = [];
        defaultTriangleBRDF = [];
        materialsTransitionPosition = 0;
        materialsTransitionSlope = 0;
        materialStrengthsSpecular = [];
        materialStrengthsDiffraction = [];
        defaultTriangleMaterial = [];        
    end

    methods
        function [obj, pointer] = ObjectSettings(buffer, pointer, numberOfFrequencies)
            if nargin < 1 
                buffer = []; 
            end

            if ~isempty(buffer)
                nameLength = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                obj.name = strtrim(native2unicode(buffer(pointer: pointer + nameLength - 1), 'UTF-8'));
                pointer = pointer + nameLength;    
                
                obj.uniqueIndex = typecast(swapbytes(buffer(pointer:pointer+ 3)), 'int32');
                pointer = pointer + 4;
                obj.isStaticMesh = logical(typecast(swapbytes(buffer(pointer:pointer+3)), 'int32'));
                pointer = pointer + 4;
                obj.isSkeletalMesh = logical(typecast(swapbytes(buffer(pointer:pointer+3)), 'int32'));
                pointer = pointer + 4;
    
                resourceLength = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                obj.resourcePath = strtrim(native2unicode(buffer(pointer: pointer + resourceLength - 1), 'UTF-8'));
                pointer = pointer + resourceLength;
    
                descriptionLength = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                obj.description = strtrim(native2unicode(buffer(pointer: pointer + descriptionLength - 1), 'UTF-8'));
                pointer = pointer + descriptionLength;

                obj.drawDebugFirstOccurrence = logical(typecast(swapbytes(buffer(pointer:pointer+3)), 'int32'));
                pointer = pointer + 4;
    
                obj.brdfTransitionPosition = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.brdfTransitionSlope = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.brdfExponentsSpecular = typecast(swapbytes(buffer(pointer:pointer+4*numberOfFrequencies-1)), 'single');
                pointer = pointer + 4 * numberOfFrequencies;
                obj.brdfExponentsDiffraction = typecast(swapbytes(buffer(pointer:pointer+4*numberOfFrequencies-1)), 'single');
                pointer = pointer + 4 * numberOfFrequencies;
                obj.defaultTriangleBRDF = typecast(swapbytes(buffer(pointer:pointer+4*numberOfFrequencies-1)), 'single');
                pointer = pointer + 4 * numberOfFrequencies;
    
                obj.materialsTransitionPosition = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.materialsTransitionSlope = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.materialStrengthsSpecular = typecast(swapbytes(buffer(pointer:pointer+4*numberOfFrequencies-1)), 'single');
                pointer = pointer + 4 * numberOfFrequencies;
                obj.materialStrengthsDiffraction = typecast(swapbytes(buffer(pointer:pointer+4*numberOfFrequencies-1)), 'single');
                pointer = pointer + 4 * numberOfFrequencies;
                obj.defaultTriangleMaterial = typecast(swapbytes(buffer(pointer:pointer+4*numberOfFrequencies-1)), 'single');
                pointer = pointer + 4 * numberOfFrequencies;
            end
        end
    end
end