//.geo file used to generate geometry
//edit as needed
//compile using a .msh compiler

//DO NOT MODIFY THESE FIELDS
SetFactory("OpenCASCADE");
Mesh.CharacteristicLengthFromPoints        = 0;
Mesh.CharacteristicLengthFromCurvature    = 0;
Mesh.CharacteristicLengthExtendFromBoundary = 0;

//set up global geometric constraints
s = 20; //define element size, elements are QUAD4
w = 12000; //film width in nm
center = 3280; //relative ball initial center position
h = 250; //film thickness in nm

//DO NOT MODIFY THESE FIELDS: build film geometry
Rectangle(1) = {0, 0, 0, w, h, 0};
Transfinite Curve {1, 3} = (w / s) + 1 Using Progression 1;
Transfinite Curve {2, 4} = (h / s) + 1 Using Progression 1;
Transfinite Surface {1};
Recombine Surface {1};

//define element size on the flyer
//impose a x10 refinement on the flyer along the contact surface

Field[1] = Ball; //name
Field[1].XCenter = w / 2.; //define center of the field
Field[1].YCenter = center; //define center of the field
Field[1].ZCenter = 0; //define center of the field
Field[1].Radius = 2600; //define radius of the field
Field[1].VIn = 50 * s; //inside the field, make element size 50 times bigger than the film
Field[1].VOut = 5 * s; //outside the field, make the element size 5 times bigger than the film
Field[1].SurfacesList = {3}; //apply to surface 3 (flyer)
Background Field = 1; //set as background field


//define flyer's center, left, and right points
Point(5) = {(w / 2.) - (6000/2), center, 0, 1000};
Point(6) = {(w / 2.), center, 0};
Point(7) = {(w / 2.) + (6000/2), center, 0, 1000};

//generate circle
Circle(6) = {7, 6, 5};
Curve Loop(2) = {5, 6};
Curve Loop(3) = {5, 6};

//assign label to the surface
Plane Surface(3) = {3};

//assign names, these are arbitrary and can be modified
Physical Surface("plate", 7) = {1};
Physical Surface("ball", 14) = {2};
Physical Curve("ball_bottom", 9) = {6};
Physical Curve("top", 10) = {3};
Physical Curve("bottom", 11) = {1};
Physical Curve("right", 12) = {2};
Physical Curve("left", 13) = {4};

//close the half-disc
Line(7) = {5, 7};
Curve Loop(2) = {7, 6};
Plane Surface(2) = {2};

//compile 2D mesh
Mesh 2;

