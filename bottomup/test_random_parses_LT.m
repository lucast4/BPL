function J = test_random_parses_LT(I)
    T = make_thin(I); % get thinned image
    J = extract_junctions(T); % get endpoint/junction features of thinned image

end


% Apply thinning algorithm. First it closes holes
% in the image.
%
% Input
%  I: [n x n boolean] raw image.
%    images are binary, where true means "black"
%
% Output
%  T: [n x n boolean] thinned image.
function T = make_thin(I)
    I = bwmorph(I,'fill');
    T = bwmorph(I,'thin',inf);
end