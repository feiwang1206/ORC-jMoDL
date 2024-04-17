% Cdiff_test.m
% test Cdiff object (and Cmask too)

if 1 % look at 2nd order case
	nx = 8; ny = 6;
	C = Cdiff(ones(nx,ny), 'order', 2);
	Cf = C(:,:);
	t = reshape(Cf', nx*ny, nx*ny, []);
	im(t)
	t = zeros(nx,ny); t(nx/2+1,ny/2+1) = 1;
	t = C' * (C * t);
	im(t)
end

if ~isvar('C2')
	nx = 16; ny = 14;
	nx = 512; ny = 500; % for large images, the mex file is much faster!
	mask = [0 0 [nx ny]/2-5 0 1];
	mask = conv2(double(ellipse_im(nx, ny, mask) > 0), ones(2), 'same') > 0;
%	mask = ones(nx,ny); % all
	mask = logical(mask);

	if 1, printm 'test penalty_mex'
		x = single(mask);
		offsets = [nx-1];
		offsets = int32(offsets);
		d1 = penalty_mex('diff2,forw1', x, offsets);
		d2 = penalty_mex('diff2,forw1', x, offsets, int32(ndims(x)));
		if any(d1(:) ~= d2(:)), error 'bug', end

		x1 = penalty_mex('diff2,back1', d1, offsets);
		x2 = penalty_mex('diff2,back1', d1, offsets, int32(ndims(x)));
		if any(x1(:) ~= x2(:)), error 'bug', end
	end

	ctype = 'leak';
	ctype = 'tight';
	order = 1;
	tic
	C1 = Cdiff(mask, 'edge_type', ctype, 'offsets', '2d,hvd', ...
		'distance_power', 1., 'order', 1);
	printf('make C1 time %g', toc)

	tic
	[C2 wjk] = C2sparse(ctype, mask, 8);
	printf('make C2 time %g', toc)
	C2 = spdiag(sqrt(wjk)) * C2;
	C2 = C2(:,mask(:));

	if 0
		cpu tic
		b1 = Cmask('tight,2d,hvd', mask);
		cpu toc 'make scale time:'
		b1(:,:,[3 4]) = b1(:,:,[3 4]) / sqrt(sqrt(2));
		if 0
			b1 = reshape(sqrt(wjk), [nx ny 4]);
		end

		cpu tic
		b2 = penalty_mex('scales,tight', single(mask), C1.arg.offsets, 1.);
		b2 = double(b2);
		cpu doc 'make scale time:'

		im clf, im(131, b1), im(132, b2), im(133, b1-b2)
		printf('old vs new: %g%%', max_percent_diff(b1, b2))
	return
	end

	rand('state', 0)
	x = rand(nx, ny);
	x = dsingle(x);
	x = x .* mask;

%prompt
end

xm = double(x(mask(:)));
cpu tic
d1 = C1 * x; 
cpu toc 'C1 forw time:'
%d1 = dsingle(d1);

cpu tic
d2 = C2 * xm; 
cpu toc 'C2 forw time:'
%d2 = dsingle(d2);
d2 = reshape(d2, [nx ny 4]); 
printf('Cx vs penalty_mex: %g%%', max_percent_diff(d1, d2))

if im
	im clf
	im(131, d1, 'C * x'), cbar
	im(132, d2, 'penalty--mex'), cbar
	im(133, d2-d1, 'err'), cbar
prompt
end

if 1
	xx = double([xm xm]);
	cpu tic
	d11 = C1 * xx;
	cpu toc 'C1 forw time:'

	cpu tic
	d22 = C2 * xx; 
	cpu toc 'C2 forw time:'
	printf('Cxx vs penalty_mex: %g%%', max_percent_diff(d11, d22))
end

d = double(d1(:));
%d = zeros(nx,ny,4);
%d(end/2,end/2,1) = 1;

cpu tic
x1 = C1' * d;
cpu toc 'C1''d time:'
%x1 = dsingle(x1);
x1 = embed(x1, mask);
%x1 = reshape(x1, nx, ny);

cpu tic
x2 = C2' * d;
%x2 = double(x2);
cpu toc 'C2''d time:'
x2 = embed(x2, mask);
%x2 = reshape(x2, nx, ny);

printf('C1 vs C2: %g%%', max_percent_diff(x1, x2))
if im
	im clf
	im(131, x1, 'C''d'), cbar
	im(132, x2, 'penalty--mex'), cbar
	im(133, x2-x1, 'err'), cbar
end

if 1
	dd = double([d(:) d(:)]);

	cpu tic
	x11 = C1' * dd;
	cpu toc 'C1''d time:'

	cpu tic
	x22 = C2' * dd;
	cpu toc 'C2''d time:'

	printf('C1 vs C2 for dd: %g%%', max_percent_diff(x11, x22))
end