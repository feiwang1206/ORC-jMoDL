% pet_transmission_example.m
% Example of reconstructing a PET attenuation map via penalized-likelihood
% estimation from real 2D PET transmission data.
%
% Copyright 2002-12-19, Jeff Fessler, The University of Michigan

%
% read raw data
%
if ~isvar('yi'), printm 'raw data'
	ddir = path_find_dir([filesep 'data']);	% adjust path if needed
	ddir = [ddir filesep 'pet,trans,2d,sino' filesep];
	yi = double(mat_read([ddir 'phan,trans.mat']));
	bi = double(mat_read([ddir 'phan,blank.mat']));
	im pl 2 2, im(1, yi, 'yi: transmission scan')
	im(2, bi, 'bi: blank scan')

	% system model for ecat921 PET scanner geometry
	ig = image_geom('nx', 128, 'dx', 0.421875, 'dy', 0.421875); % cm
%		'center_x', 0.5, 'center_y', -0.5, ...
	sg = sino_geom('par', 'nb', size(yi,1), 'na', size(yi,2), ...
		'dr', 0.3375, 'offset_r', 0.5, ...
		'orbit_start', -15);
prompt
end

%
% FBP image
%
if ~isvar('xfbp'), printm 'do FBP'
	kernel = gaussian_kernel(3);
%	kernel = [1];
	xfbp = tr_fbp(sg, ig, max(yi,1), bi, 0*bi, 'kernel', kernel);
% fix: correct for backproject scaling problem; probably incorrect!
%	xfbp = xfbp * na/pi * f.pixel_size / f.ray_spacing;
	xfbp = max(xfbp,0);
	im(3, xfbp, 'fbp'), cbar

	ig.mask = ig.circ(26, 21, 0, 3) > 0;
	im(4, ig.mask+6*xfbp, 'mask check')
prompt
end


%
% strip integral system matrix with mask for iterative reconstruction.
%
if ~isvar('G2'), printm 'G2'
%	G2 = Gtomo2_wtmex(sg, ig); % preferable for speed
	G2 = Gtomo2_strip(sg, ig, 'strip_width', sg.dr); % slower but universal
prompt
end


if ~isvar('Gb'), printm 'make Gb' % block system object for ordered-subsets
	f.nblock = 5;
	Gb = Gblock(G2, f.nblock, 0);
prompt
end


if ~isvar('R'), printm 'make R' % regularizer object
	f.l2b = 10.5;
	f.delta = 0.03;
	f.pot = 'huber';
%	R = Robject(ig.mask, 'type_denom', 'matlab', ...
%		'beta', 2^f.l2b, 'potential', f.pot, 'delta', f.delta);
	f.pot = 'hyper3';
	R = Reg1(ig.mask, 'type_denom', 'matlab', ...
		'beta', 2^f.l2b, 'pot_arg', {f.pot, f.delta});
prompt
end


%
% matlab iterations
%
if ~isvar('xmat'), printm 'matlab T-PL-OS-SPS'
	f.niter = 8+1;
	f.niter = 16+1;
	f.pixmax = 0.4;
	xinit = max(xfbp,0);

	xmat = tpl_os_sps(xinit(ig.mask), Gb, yi, bi, [], R, ...
		f.niter, f.pixmax, 'pc');
	xmat = ig.embed(xmat);

	im clf, im(xmat, 'T-PL-OSPS iterations (0th is FBP)')
prompt
end

% nice figure for book
if 1
	im clf
	im(211, yi, 'sinogram yi')
	clim = [0 0.2];
	im(223, xfbp, 'FBP', clim), cbar
	im(224, xmat(:,:,end), 'Statistical', clim), cbar
end
