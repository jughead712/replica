function [atlas_patches, atlas_Y] = get_train_patches(atlas_tgt, atlases, ps, lm)
%GET_TRAIN_PATCHES Summary of this function goes here
%
%   Args:
%       atlases: 
%       ps: A struct containing the parameters for training.
%
%   Output:
%       atlas_patches:
%       atlas_Y:

    atlas_t1w = atlases{1};  % T1w-image will always be first element
    
    patch_size = ps.patch_size;
    L = patch_size(1) * patch_size(2) * patch_size(3);
    
    if nargin > 3
        [I, J, K, orig, n] = get_train_samples(atlas_t1w, atlas_tgt, ps, lm);
    else
        [I, J, K, orig, n] = get_train_samples(atlas_t1w, atlas_tgt, ps);
    end
    
    if ps.use_context_patch == 0
        atlas_patches = zeros(3*L, n);     
    elseif ps.use_context_patch == 1
        atlas_patches = zeros(3*L+32, n);
    else
        error('param_struct.use_context_patch needs to be 0 or 1');
    end
    atlas_Y = zeros(1, n);
    
    for viter = 1:n
        i = I(viter);
        j = J(viter);
        k = K(viter);
        patches = get_patch(atlases, i, j, k, orig, L, ps);
        atlas_patches(:, viter) = patches;
        atlas_Y(viter) = atlas_tgt(i, j, k);
    end
end

