function [locationCentimeters, rotationQuat] = matlabTFormToUnreal(TForm)

    locationMeters = TForm(1:3, 4);    
    locationCentimeters = locationMeters * 100;
    locationCentimeters(2) = -locationCentimeters(2); 

    rotationMatrix = TForm(1:3, 1:3);
    q = quaternion(rotationMatrix, 'rotmat', 'frame'); 
    [w, x, y, z] = parts(q); 
    rotationQuat = [x, -y, z, w]; 
end
