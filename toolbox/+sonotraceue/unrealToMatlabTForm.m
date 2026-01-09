function TForm = unrealToMatlabTForm(locationCentimeters, rotationQuat)

    locationMeters = locationCentimeters / 100;
    locationMeters(2) = -locationMeters(2);

    x = rotationQuat(1);
    y = rotationQuat(2);
    z = rotationQuat(3);
    w = rotationQuat(4);
    q = quaternion(w, x, -y, z);
    rotationMatrix = rotmat(q, 'frame');

    TForm = eye(4); 
    TForm(1:3, 1:3) = rotationMatrix;
    TForm(1:3, 4) = locationMeters;
end