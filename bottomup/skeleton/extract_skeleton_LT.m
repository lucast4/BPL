% Compute a bottom-up character skeleton.
% This algorithm should be deterministic.
%
% Input
%  I: [N x N] binary image (true = black)
%  bool_viz: visualize the results? (default = true)
%
%  Z: [struct] graph structure
%    fields
%    .n: number of nodes
%    .G: [n x 2] node coordinates
%    .E: [n x n boolean] adjacency matrix
%    .EI: [n x n cell], each cell is that edge's index into trajectory list
%         S. It should be a cell array, because there could be two paths
%    .S: [k x 1 cell] edge paths in the image 
%

function U = extract_skeleton(I,extra_junctions,bool_viz)
    nj = 5; % num pixels in neighborhood of extra jhunctions to test, if no auto-extracted
    % junctions found in this neighborhood, then include 
    
    if ~exist('bool_viz','var')
        bool_viz = false;
    end
    
    assert(UtilImage.check_black_is_true(I));
    
    T = make_thin(I); % get thinned image
    % disp(T)
    J = extract_junctions(T); % get endpoint/junction features of thinned image
    % add junctions by hand
    % disp(sum(J(:)))
    if ~isempty(extra_junctions)
      % inds = sub2ind(size(I), extra_junctions(:,1), extra_junctions(:,2));
      % J(inds) = 1;

      % check if any junctions to add are too close to current junctions
      for i=1:size(extra_junctions,1)
        jthis = extra_junctions(i,:);

        x1 = max(1, jthis(1)-nj);
        x2 = max(1, jthis(2)-nj);
        y1 = min(size(J,1), jthis(1)+nj);
        y2 = min(size(J,2), jthis(2)+nj);
        tmp = J(x1:y1, x2:y2); % check if already have a junction close.
        if ~any(tmp(:))
          % snap this junction onto the nearest skeletion pt
          if false
            disp(['ADDING JUNCTION: ' num2str(jthis)]);
            disp('neighborhood (skel) before snapping')
            disp(T(jthis(1)-2:jthis(1)+2, jthis(2)-2:jthis(2)+2));
          end
          if T(jthis(1), jthis(2))==0
            % then snap to nearest skel point
            pts_in_T = find(T);
            [xinds, yinds] = ind2sub(size(T), pts_in_T);
            k = dsearchn(int16([xinds, yinds]), int16(jthis));
            jthis = [xinds(k) yinds(k)]; % snapped value
            if false
              disp(['new coordinates after snapping: ' num2str(jthis)]);
              disp('New neighborhood (skel)')
              try
                disp(T(jthis(1)-2:jthis(1)+2, jthis(2)-2:jthis(2)+2));
              catch err
              end
            end
          end
          J(jthis(1), jthis(2)) = 1;
        end
      end
    end

    U = trace_graph(T,J,I); % trace paths between features
    B = U.copy();
    U.clean_skeleton;
    
    if bool_viz
       sz = [313 316]; % figure size      
       h = figure;
       pos = get(h,'Position');
       pos(3:4) = sz;
       set(h,'Position',pos);
       
       % visualize original image
       subplot(2,2,1);
       viz_skel.plot_image(I);
       title('Image');
       
       % visualize thinned image
       subplot(2,2,2);
       viz_skel.plot_junctions(T,J); 
       title('Thinned');
       
       % visualize paths in thinned image
       subplot(2,2,3);
       B.plot_skel;
       title('Graph (raw)');
       
       subplot(2,2,4);
       U.plot_skel;
       title('Graph (cleaned)');
       
       set(gcf,'Position',pos);
       pause(.01);
       drawnow
    end
    
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