% measurement in centimetre
h_cm    = 150;
near_cm = 140;
mid_cm  = 250;

% angle of geometric system
camera_angle = atand(mid_cm/h_cm);
rayToNear    = sqrt(h_cm^2 + near_cm^2);
perpenToMid  = (mid_cm-near_cm)*cosd(camera_angle);
half_beam    = asind(perpenToMid/rayToNear);
far_cm       = h_cm*tand(camera_angle+half_beam);

% height of far area
bimg_px = 180; % pixel
bimg = bimg_px*3.58/4368; % cm - canon 5D spec
f = 2.4; % focal length
theta = camera_angle;
alpha = half_beam;

% triangle at far end
gamma = atand((f*tand(alpha)-bimg)/f);
beta_far = theta + gamma; 
a_f = bimg*h_cm/f*cosd(gamma)/cosd(beta_far);
S_b = a_f*cosd(alpha)/cosd(theta+alpha);
c_f = S_b*sind(theta)/cosd(alpha);

% triangle at near end
beta_near = atand((near_cm+S_b)/h_cm);
a_n = S_b*cosd(beta_near)/cosd(theta-beta_near);
b_n = a_n*f/cosd(alpha)/h_cm*cosd(theta-alpha);

scaling = b_n/bimg;
b_n_px = bimg_px*scaling;