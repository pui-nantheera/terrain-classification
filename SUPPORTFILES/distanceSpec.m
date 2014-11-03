% measurement in centimetre
h_cm    = 150;
near_cm = 140;
mid_cm  = 250;

camera_angle = atand(mid_cm/h_cm);
rayToNear    = sqrt(h_cm^2 + near_cm^2);
perpenToMid  = (mid_cm-near_cm)*cosd(camera_angle);
half_beam    = asind(perpenToMid/rayToNear);
far_cm       = h_cm*tand(camera_angle+half_beam);