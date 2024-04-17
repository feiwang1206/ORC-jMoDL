function recon = reconstruction_MoDL(rawdata,net,param)
    
    shot=1;
    P=param.P;
    P{2}=param.P{2}*max(abs(col(rawdata{shot})));
    recon{shot} = regularizedReconstruction(param.F{shot},(double(rawdata{shot})),P{:},'maxit',10,...
        'verbose_flag', 0,'tol',1e-5);
    shot=2;
    P=param.P;
    P{2}=param.P{2}*max(abs(col(rawdata{shot})));
    recon{shot} = regularizedReconstruction(param.F{shot},(double(rawdata{shot})),P{:},'maxit',10,...
        'verbose_flag', 0,'tol',1e-5);

    field=param.field0;

    norm=max(abs(col(recon{1}+recon{2})/2));
    for nn=1:3
        image=zeros([param.dim 5]);
        image(:,:,:,1)=real(gather(recon{1}))/norm;
        image(:,:,:,2)=real(gather(recon{2}))/norm;
        image(:,:,:,3)=imag(gather(recon{1}))/norm;
        image(:,:,:,4)=imag(gather(recon{2}))/norm;
        image(:,:,:,5)=gather(field)/1000;
        tmp=double(predict(net{nn}.net,image)); 
        field = tmp(:,:,:,1)*100+field;
        recon0=(tmp(:,:,:,2)+1i*tmp(:,:,:,3))*norm+(recon{1}+recon{2})/2;

        maxiter=5;
        if nn<3
            shot=1;
            if param.GPU==1
                param.F{shot}=orc_segm_nuFTOperator_multi_savetime(param.F0{shot},gpuArray(field));
            else
                param.F{shot}=orc_segm_nuFTOperator_multi_savetime(param.F0{shot},field);
            end
            P=param.P;
            P{2}=param.P{2}*max(abs(col(rawdata{shot})));
            recon{shot} = regularizedReconstruction(param.F{shot},double(rawdata{shot}),P{:},'maxit',maxiter,...
                'verbose_flag', 0,'tol',1e-5,'z0',recon0);
            shot=2;
            if param.GPU==1
                param.F{shot}=orc_segm_nuFTOperator_multi_savetime(param.F0{shot},gpuArray(field));
            else
                param.F{shot}=orc_segm_nuFTOperator_multi_savetime(param.F0{shot},field);
            end
            P=param.P;
            P{2}=param.P{2}*max(abs(col(rawdata{shot})));
            recon{shot} = regularizedReconstruction(param.F{shot},double(rawdata{shot}),P{:},'maxit',maxiter,...
                'verbose_flag', 0,'tol',1e-5,'z0',recon0);
        end
    end
    shot=4;
    if param.GPU==1
        param.F{shot}=orc_segm_nuFTOperator_multi_savetime(param.F0{shot},gpuArray(field));
    else
        param.F{shot}=orc_segm_nuFTOperator_multi_savetime(param.F0{shot},field);
    end
    P=param.P;
    P{2}=param.P{2}*max(abs(col([rawdata{1};rawdata{2}])))*2;
    recon{shot} = regularizedReconstruction(param.F{shot},[rawdata{1};rawdata{2}],P{:},'maxit',5,...
        'verbose_flag', 0,'tol',1e-5,'z0',recon0);

    recon{1}=gather(recon{1});
    recon{2}=gather(recon{2});
    recon{3}=gather(field);    
    recon{4}=gather(recon{4});

    printf('complete')
        
end
