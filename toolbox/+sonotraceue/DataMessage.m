classdef DataMessage
    
    properties
        type = 0;
        order = [];
        strings = {};
        integers = [];
        floats = [];
    end
    
    methods
        function obj = DataMessage(type, order, strings, integers, floats)
            if nargin < 1 
                server = []; 
            end

            if nargin < 1 
                server = []; 
            elseif nargin == 1
                server = type;
            elseif nargin > 1
                obj.type = type;
                obj.order = order;
                obj.strings = strings;
                obj.integers = integers;
                obj.floats = floats;
                return;
            end

            if ~isempty(server)

                % Data size
                dataDataSize = uint8(read(server, 4, "uint8"));
                dataSize = typecast(swapbytes(dataDataSize), "int32");
    
                % Read all data into a buffer in one operation
                buffer = uint8(read(server, dataSize, "uint8"));
    
                % Use a pointer-based approach to parse the data
                pointer = 1;                

                % Type 
                obj.type = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                
                % Order
                orderCount = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                for i = 1:orderCount
                    obj.order(i) = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                    pointer = pointer + 4;
                end

                % Strings
                stringsCount = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                for i = 1:stringsCount
                    stringSize = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                    pointer = pointer + 4;
                    currentString = strtrim(native2unicode(buffer(pointer: pointer + stringSize - 1), 'UTF-8'));
                    pointer = pointer + stringSize;
                    obj.strings{i} = currentString;
                end

                % Integers
                integerCount = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                for i = 1:integerCount
                    obj.integers(i) = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                    pointer = pointer + 4;
                end

                % Floats
                floatsCount = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                for i = 1:floatsCount
                    obj.floats(i) = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                    pointer = pointer + 4;
                end               
            end
        end        
    end
end

