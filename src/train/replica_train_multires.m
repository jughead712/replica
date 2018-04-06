function replica_rfs = replica_train_multires(atlas_struct, param_struct)
%REPLICA_training trains a multiresolution REPLICA random forest
%   given atlases and parameters for training
%
%   Args:
%       atlas_struct: Refer to replica_demo.m to specify parameters in this
%                     struct
%       param_struct: A struct containing the parameters for training
%           (see utilities/multires/default_param_struct_multires.m for
%            an example of the parameters)
%
%   Output:
%       replica_rf: replica random forest regressor

% rename for convenience, since this is used all over
ps = param_struct;

% initialize some parameters
n_training_samples = ps.no_of_training_samples;
n_atlas_brains = length(atlas_struct.source);
ps.n_training_samples_per_brain = ...
    round(n_training_samples/n_atlas_brains);
H = fspecial3('gaussian', ps.gaussian_kernel_size);

% resolutions over which to calculate rfs
resolutions = {'low', 'intermediate', 'high'};

% hold all training patches and mapping value
all_patches = {[], [], []};
all_y = {[], [], []};

% iterate over all given training data and all resolutions
for iter=1:n_atlas_brains
    [src0, trg0] = get_imgs(atlas_struct, ps, iter);
    [trg, ~] = multiresolution(trg0, H);
    [src, g] = multiresolution(src0, H);
    for r=1:3
        % open the source and target images
        fprintf('getting patches for %s resolution on iter %d\n', ...
                resolutions{r}, iter);
        if r > 1
            rs_trg = interp3(trg{r-1}, 1);
            rs_trg = interp3(rs_trg, g{r}{1}, g{r}{2}, g{r}{3});
        else
            rs_trg = [];
        end
        [p, y] = train_patches_multires(src{r}, trg{r}, ps, r, rs_trg, ...
                                        src0, trg0, g{3});
        all_patches{r} = [all_patches{r}, p];
        all_y{r} = [all_y{r}, y];
    end
end

% manual memory management, since some of the objects get very large
clearvars -except all_patches all_y resolutions ps

% holds trained random forest regressors
replica_rfs = cell(3,1);

% set options for training rf regressors
opts = statset('UseParallel', 'always');

% train regressor for all resolution levels
for r=1:3
    fprintf('training for %s resolution\n', resolutions{r});
    replica_rfs{r} = TreeBagger(ps.nTrees{r}, all_patches{r}(:,1:end)', ...
                                all_y{r}(:,1:end)', ...
                                'method','regression', 'Options', opts);
end

end


function [src, trg] = get_imgs(atlas_struct, ps, iter)
% get the source and target images for processing
    [src, dim] = open_atlas(atlas_struct.source{iter}, ...
                            ps.w4{3}, ps.r4{3}, ...
                            'isT1', true, ...
                            'BrainMask', atlas_struct.brainmasks{iter}, ...
                            'WMPeakNormalize', ps.wm_peak_normalize, ...
                            'fcmeans', ps.fcmeans);  
    [trg, ~] = open_atlas(atlas_struct.target{iter}, ...
                          ps.w4{3}, ps.r4{3}, ...
                          'isT1', false, ...
                          'BrainMask', atlas_struct.brainmasks{iter}, ...
                          'WMPeakNormalize', ps.wm_peak_normalize, ...
                          'fcmeans', ps.fcmeans, ...
                          'T1wNormImg', unpad(src, ps.w4{3}, ps.r4{3}, dim));
end