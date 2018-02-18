%script for analyzing surface-based data -- clean-up in progress

function analyzeSurfData ( subj_list )


%% definitions
data_dir='work_pipeline';



surfdisp_dir=sprintf('%s/surfdisp_singlestruct_striatum_unbiasedAvg_affine',data_dir);

template_byu=sprintf('%s/template/dstriatum_nii.byu',surfdisp_dir);



targets={'caudal_motor','executive','limbic','occipital','parietal','rostral_motor','temporal'};

targets_s={'cd_m','ex','li','oc','pa','ro_m','te'};

%% load in subject/group info

subjects=importdata(subj_list);

%need to make sure te following is updated based on new subject list
group_name={'CTRL','PD'};

controls=[];
patients=[];

%look for PD substring in subj name to define patients
ind=strfind(subjects,group_name{2});
for i=1:length(ind)
	if(~isempty(ind{i}))
		patients=[patients,i];
	else
		controls=[controls,i];
	end
end

%controls=[7:14];
%patients=[1:6];

groups{1}=controls;
groups{2}=patients;

contrasts={[1,2],[2,1]};

% 
% subjects=importdata('../subjects_newJune2017_completed');
% 
% group_name={'CTRL','pd'};
% controls=[7:13];
% patients=[1:6];
% groups{1}=controls;
% groups{2}=patients;
% 
% contrasts={[1,2],[2,1]};
% 


%% get template surface (in MNI space)

[p_mni,v_mni,e_mni]=readBYUSurface(template_byu,0);

nvert=length(v_mni);

%first, get labelling of left & right striatum (using x=0 to split)
hemi={'left','right'};

hemi_s={'l','r'};

hemi_label{1}=v_mni(:,1)<0;
hemi_label{2}=v_mni(:,1)>0;



%%  create parcellation based on surface tracking


all_maxlabels=zeros(nvert,length(subjects));

for s=1:length(subjects)
    
    
    subj=subjects{s};
    conn_matrix_txt=sprintf('%s/%s/dwi/uncorrected_denoise_unring_eddy/vertexTract/matrix_seeds_to_all_targets',data_dir,subj);
    
    conn=importdata(conn_matrix_txt);
   
    if(size(conn,2))==8
        conn=conn(:,1:(end-1));%strip off last col (all_segs target)
    end
    
    [maxval,maxlabel]=max(conn,[],2);
    
    for i=1:length(targets)
        i;
        sum(maxlabel==i);
    end
    
    all_maxlabels(:,s)=maxlabel;
end


%% average parcellations, voting, confidence for each group

avgparc_dir='avg_parcs';
mkdir(avgparc_dir);



for g=1:length(groups)
    
% voting for average

%first get freq fpr each

freq_maxlabels=zeros(nvert,length(targets));

for i=1:length(targets)
    
    freq_maxlabels(:,i)=sum(all_maxlabels(:,groups{g})==i,2);
    
end

[maxval, majVote_maxlabels]=max(freq_maxlabels,[],2);

if (strcmp(group_name{g},'CTRL'))
    majVote_maxlabels_ctrl=majVote_maxlabels;
end
    

writeByuWithScalarToVTK(template_byu,majVote_maxlabels,sprintf('%s/majVote_maxlabels_%s.vtk',avgparc_dir,group_name{g}));

%calculate confidence as the normalized maxval
confidence=maxval./length(groups{g});
writeByuWithScalarToVTK(template_byu,confidence,sprintf('%s/majVote_confidence_%s.vtk',avgparc_dir,group_name{g}));

    
%compute maps for each parcellation target, as the number of subjects with
%the given label (freq_maxlabels)

for i=1:length(targets)
    
writeByuWithScalarToVTK(template_byu,freq_maxlabels(:,i)./length(groups{g}),sprintf('%s/labelFreq_%s_%s.vtk',avgparc_dir,targets{i},group_name{g}));

end


%get thresholded centrol group confidence map
conf_th=0.5
writeByuWithScalarToVTK(template_byu,confidence>conf_th,sprintf('%s/majVote_confidenceMask_threshold%f_%s.vtk',avgparc_dir,conf_th,group_name{g}));

if (strcmp(group_name{g},'CTRL'))
    conf_mask=confidence>conf_th;


majVote_maxlabels_masked=majVote_maxlabels;
majVote_maxlabels_masked(conf_mask==0)=-1;
writeByuWithScalarToVTK(template_byu,majVote_maxlabels_masked,sprintf('%s/majVote_maxlabels_maskedCtrlConfTh_%s.vtk',avgparc_dir,group_name{g}));

end

end



%% compute avg control, avg PD, and difference map

% subjects=importdata('subjects_1scan');
% controls=[1:5,19:24];
% patients=[6:18,25:31];

%subjects=importdata('subjects');
%subjects=subjects(1:18);
%controls=1:10
%patients=11:18


surfdisp_data=zeros(length(subjects),nvert);


for s=1:length(subjects)
    
    subj=subjects{s};
    
    %get T1-based surf displacement data
    surfdisp_txt=sprintf('%s/%s/dstriatum.surf_inout.txt',surfdisp_dir,subj);
    inout=importdata(surfdisp_txt);
    surfdisp_data(s,:)=inout;
   
    
end
disp_dir='avg_disp';



mkdir(disp_dir);


for g=1:length(groups)
    
mean_dispdata=mean(surfdisp_data(groups{g},:),1)';
writeByuWithScalarToVTK(template_byu,mean_dispdata,sprintf('%s/mean_%s_surfdisp.vtk',disp_dir,group_name{g}));

end

for c=1:length(contrasts)
    
    diff_dispdata=mean(surfdisp_data(groups{contrasts{c}(1)},:),1) -   mean(surfdisp_data(groups{contrasts{c}(2)},:),1);
    writeByuWithScalarToVTK(template_byu,diff_dispdata',sprintf('%s/diff_%s-%s_surfdisp.vtk',disp_dir,group_name{contrasts{c}(1)},group_name{contrasts{c}(2)}));
    
end



%% write each subject's parcellation to vtk file

mkdir('subj_vtk');
for s=1:length(subjects)
    
    
    subj=subjects{s};
    conn_matrix_txt=sprintf('%s/%s/dwi/uncorrected_denoise_unring_eddy/vertexTract/matrix_seeds_to_all_targets',data_dir,subj);
    
    conn=importdata(conn_matrix_txt);
    if(size(conn,2))==8
        conn=conn(:,1:(end-1));%strip off last col (all_segs target)
    end
    
    [maxval,maxlabel]=max(conn,[],2);
    
    for i=1:length(targets)
        i;
        sum(maxlabel==i);
    end
    
    writeByuWithScalarToVTK(template_byu,maxlabel,sprintf('subj_vtk/%s.parc.vtk',subj));

end






%% get surface area (in MNI space) for each parcellation

% subjects=importdata('subjects');
% subjects=subjects(1:18);
% controls=1:10
% patients=11:18


surfarea=zeros(length(subjects),length(hemi),length(targets));
meansurfdisp_subjparc=zeros(length(subjects),length(hemi),length(targets));

for s=1:length(subjects)
    
    subj=subjects{s};
    
    %get seeds to targets
    conn_matrix_txt=sprintf('%s/%s/dwi/uncorrected_denoise_unring_eddy/vertexTract/matrix_seeds_to_all_targets',data_dir,subj);
    conn=importdata(conn_matrix_txt);
    if(size(conn,2))==8
        conn=conn(:,1:(end-1));%strip off 1st col (all_segs target)
    end
    %get T1-based surf displacement data
    surfdisp_txt=sprintf('%s/%s/dstriatum.surf_inout.txt',surfdisp_dir,subj);
    inout=importdata(surfdisp_txt);
    
    
    [maxval,maxlabel]=max(conn,[],2);
    
    
    
    nverts=zeros(length(hemi),length(targets));
    %figure;
    subploti=1;
    for h=1:length(hemi)
        for i=1:length(targets)
            
            i;
            selection=(maxlabel==i & hemi_label{h});
            nverts(h,i)=sum(selection);
            surfarea(s,h,i)=computeSurfArea(v_mni,e_mni,selection);
            
%             disp(sprintf('%s %s, nverts=%d, area=%f',hemi{h},targets{i},nverts(h,i),surfarea(s,h,i)));
%             
%              subplot(length(hemi),length(targets),subploti);
%              hist(inout(selection)); subploti=subploti+1;
%             xlim([-3,3]); ylim([0,1500]);
%             titletext=sprintf('%s %s',hemi_s{h},targets_s{i});
%             title(titletext);
            
            meansurfdisp_subjparc(s,h,i)=mean(inout(selection));
        end
    end
    
    
    
end


%% look at surf displacements using majVoting parcellation


%subjects=importdata('subjects_1scan');
%controls=[1:5,19:24];
%patients=[6:18,25:31];

%subjects=subjects(1:18);
%controls=1:10
%patients=11:18


meansurfdisp=zeros(length(subjects),length(hemi),length(targets));

for s=1:length(subjects)
    
    subj=subjects{s};
    
    %get T1-based surf displacement data
    surfdisp_txt=sprintf('%s/%s/dstriatum.surf_inout.txt',surfdisp_dir,subj);
    inout=importdata(surfdisp_txt);
    
    %figure;
    subploti=1;
    for h=1:length(hemi)
        for i=1:length(targets)
            
            i;
            selection=(majVote_maxlabels_ctrl==i&hemi_label{h});
            
            %  subplot(length(hemi),length(targets),subploti);
            %  hist(inout(selection)); subploti=subploti+1;
            % xlim([-3,3]); ylim([0,1500]);
            % titletext=sprintf('%s %s',hemi_s{h},targets_s{i});
            % title(titletext);
            
            meansurfdisp(s,h,i)=mean(inout(selection));
        end
    end
    
end



%% evaluate FA along fibres in each parcellation


mean_fa=zeros(length(subjects),2,length(targets));

for s=1:length(subjects)
    subj=subjects{s};
    fdt_matrix=sprintf('%s/%s/dwi/uncorrected_denoise_unring_eddy/vertexTract/fdt_matrix2.dot',data_dir,subj);
    
    %following commandis memory intensive:
    mat=spconvert(load(fdt_matrix));
    
    maskimg=sprintf('%s/%s/dwi/uncorrected_denoise_unring_eddy/bedpost.bedpostX/nodif_brain_mask_bin.nii.gz',data_dir,subj);
    mask=load_nifti(maskimg);
    
    faimg=sprintf('%s/%s/dwi/uncorrected_denoise_unring_eddy/dti_FA.nii.gz',data_dir,subj);
    fa=load_nifti(faimg);
    
    fa_mat=fa.vol(mask.vol==1);
    
    tract_fa=mat*fa_mat./(mat*ones(size(fa_mat)));
    
    
    
    for h=1:length(hemi)
        for i=1:length(targets)
            
            i;
            selection=(majVote_maxlabels_ctrl==i&hemi_label{h});
            
            
            mean_fa(s,h,i)=mean(tract_fa(selection));
        end
    end
    
    % generate probabilistic maps of tracts emanating from each parcellation:

    probtracts_nii=mask;
    
   probtracts_dir=sprintf('%s/%s/dwi/uncorrected_denoise_unring_eddy/vertexTract/probmaps_avgparc',data_dir,subj);
   mkdir(probtracts_dir);
    
    for h=1:length(hemi)
        for i=1:length(targets)
            
            i;
            
            selection=(majVote_maxlabels_ctrl==i&hemi_label{h});
            probtracts=mean(mat(selection,:),1);
            probtracts_nii.vol(mask.vol==1)=probtracts;
            probtracts_file=sprintf('%s/probmap.%s.%s.nii.gz',probtracts_dir,hemi{h},targets{i});
            save_nifti(probtracts_nii,probtracts_file);

        end
    end
    
    
    
end


 


%% Write data to tables:
target_order=[3,2,6,1,5,4,7];
% generate variable for output order of csv files
r=1;
var_names={};
for t=1:length(targets)
    for h=1:2
        var_names{r}=sprintf('%s_%s',hemi{h},targets{target_order(t)});
        disp(var_names{r});
        r=r+1;
    end
end

%% write surf disp data to table
out_data=zeros(length(subjects),length(targets)*2);


for s=1:length(subjects)
    structi=1
    for t=1:length(targets)
        for h=1:2
            
            out_data(s,structi)=meansurfdisp(s,h,target_order(t));
            structi=structi+1;
        end
    end
    
end

surfdisp_table=array2table(out_data,'VariableNames',var_names,'RowNames',subjects);

writetable(surfdisp_table,'meansurfdisp_avgsurfparc.csv','WriteRowNames',1,'WriteVariableNames',1);



%% write surf area data to table (using previous table format)
out_data=zeros(length(subjects),length(targets)*2);
target_order=[3,2,6,1,5,4,7];

for s=1:length(subjects)
    structi=1
    for t=1:length(targets)
        for h=1:2
            
            out_data(s,structi)=surfarea(s,h,target_order(t));
            structi=structi+1;
        end
    end
    
end

surfarea_table=array2table(out_data,'VariableNames',var_names,'RowNames',subjects);

writetable(surfarea_table,'surfarea.csv','WriteRowNames',1,'WriteVariableNames',1);




%%  write FA data to table
out_data=zeros(length(subjects),length(targets)*2);
target_order=[3,2,6,1,5,4,7];

for s=1:length(subjects)
    structi=1
    for t=1:length(targets)
        for h=1:2
            
            out_data(s,structi)=mean_fa(s,h,target_order(t));
            structi=structi+1;
        end
    end
    
end


fa_table=array2table(out_data,'VariableNames',var_names,'RowNames',subjects);

writetable(fa_table,'meanFA_avgsurfparc.txt','WriteRowNames',1,'WriteVariableNames',1);

%% save all the tables to a mat file:

save('tables.mat','fa_table','surfdisp_table','surfarea_table');


% %% plotting below:
% 
% 
% %% plot avg surf area
% 
% mean_left=squeeze(mean(surfarea(:,1,:),1))
% mean_right=squeeze(mean(surfarea(:,2,:),1))
% 
% std_left=squeeze(std(surfarea(:,1,:),0,1))
% std_right=squeeze(std(surfarea(:,2,:),0,1))
% 
% figure; errorbar(mean_left,std_left);
% figure; errorbar(mean_right,std_right);
% 
% %% plot avg mean surf disp
% 
% mean_left=squeeze(mean(meansurfdisp(:,1,:),1))
% mean_right=squeeze(mean(meansurfdisp(:,2,:),1))
% 
% std_left=squeeze(std(meansurfdisp(:,1,:),0,1))
% std_right=squeeze(std(meansurfdisp(:,2,:),0,1))
% 
% figure; errorbar(mean_left,std_left); ylim([-2,2]);
% figure; errorbar(mean_right,std_right); ylim([-2,2]);
% 
% 
% 
% 
% %% plot mean surf disp avgparc ctrl pd
% 
% for h=1:2
%    
% mean_ctrl=squeeze(mean(meansurfdisp(controls,h,:),1))
% std_ctrl=squeeze(std(meansurfdisp(controls,h,:),0,1))
%     
% mean_pd=squeeze(mean(meansurfdisp(patients,h,:),1))
% std_pd=squeeze(std(meansurfdisp(patients,h,:),0,1))
% 
% 
% figure; errorbar(mean_ctrl,std_ctrl); %ylim([-2,2]);
% hold on; errorbar(mean_pd,std_pd); %ylim([-2,2]);
% set(gca,'XTick',[1:7],'XTickLabels',targets_s);
% title(sprintf('PD vs CTRL, %s striatum',hemi{h}));
% 
% legend({'CTRL','PD'});
% end
% 
% 
% 
% %% plot surf area ctrl pd
% 
% for h=1:2
%    
% mean_ctrl=squeeze(mean(surfarea(controls,h,:),1))
% std_ctrl=squeeze(std(surfarea(controls,h,:),0,1))
%     
% mean_pd=squeeze(mean(surfarea(patients,h,:),1))
% std_pd=squeeze(std(surfarea(patients,h,:),0,1))
% 
% 
% figure; errorbar(mean_ctrl,std_ctrl); %ylim([-2,2]);
% hold on; errorbar(mean_pd,std_pd); %ylim([-2,2]);
% set(gca,'XTick',[1:7],'XTickLabels',targets_s);
% title(sprintf('PD vs CTRL, %s striatum',hemi{h}));
% 
% legend({'CTRL','PD'});
% end
% 
% 
% %% plot parc vol ctrl pd
% 
% for h=1:2
%    
% mean_ctrl=squeeze(mean(voldata(controls,h,:),1))
% std_ctrl=squeeze(std(voldata(controls,h,:),0,1))
%     
% mean_pd=squeeze(mean(voldata(patients,h,:),1))
% std_pd=squeeze(std(voldata(patients,h,:),0,1))
% 
% 
% figure; errorbar(mean_ctrl,std_ctrl); %ylim([-2,2]);
% hold on; errorbar(mean_pd,std_pd); %ylim([-2,2]);
% set(gca,'XTick',[1:7],'XTickLabels',targets_s);
% title(sprintf('PD vs CTRL, %s striatum',hemi{h}));
% 
% legend({'CTRL','PD'});
% end
% 
% 
% %% plot mean surf disp subj-specfici parc ctrl pd
% 
% for h=1:2
%    
% mean_ctrl=squeeze(mean(meansurfdisp_subjparc(controls,h,:),1))
% std_ctrl=squeeze(std(meansurfdisp_subjparc(controls,h,:),0,1))
%     
% mean_pd=squeeze(mean(meansurfdisp_subjparc(patients,h,:),1))
% std_pd=squeeze(std(meansurfdisp_subjparc(patients,h,:),0,1))
% 
% 
% figure; errorbar(mean_ctrl,std_ctrl); %ylim([-2,2]);
% hold on; errorbar(mean_pd,std_pd); %ylim([-2,2]);
% set(gca,'XTick',[1:7],'XTickLabels',targets_s);
% title(sprintf('PD vs CTRL, %s striatum',hemi{h}));
% 
% legend({'CTRL','PD'});
% end
% 
% 
% 
% %% plot mean fa avgparc ctrl pd
% 
% for h=1:2
%    
% mean_ctrl=squeeze(mean(mean_fa(controls,h,:),1))
% std_ctrl=squeeze(std(mean_fa(controls,h,:),0,1))
%     
% mean_pd=squeeze(mean(mean_fa(patients,h,:),1))
% std_pd=squeeze(std(mean_fa(patients,h,:),0,1))
% 
% 
% figure; errorbar(mean_ctrl,std_ctrl); ylim([0.2,0.6]);
% hold on; errorbar(mean_pd,std_pd); ylim([0.2,0.6]);
% set(gca,'XTick',[1:7],'XTickLabels',targets_s);
% title(sprintf('PD vs CTRL, %s striatum',hemi{h}));
% 
% legend({'CTRL','PD'});
% end
% 
% 
% %% plot mean surf disp ctrl
% 
% 
% mean_ctrl_left=squeeze(mean(meansurfdisp(controls,1,:),1))
% mean_ctrl_right=squeeze(mean(meansurfdisp(controls,2,:),1))
% 
% std_ctrl_left=squeeze(std(meansurfdisp(controls,1,:),0,1))
% std_ctrl_right=squeeze(std(meansurfdisp(controls,2,:),0,1))
% 
% 
% % patients
% 
% 
% mean_pd_left=squeeze(mean(meansurfdisp(patients,1,:),1))
% mean_pd_right=squeeze(mean(meansurfdisp(patients,2,:),1))
% 
% std_pd_left=squeeze(std(meansurfdisp(patients,1,:),0,1))
% std_pd_right=squeeze(std(meansurfdisp(patients,2,:),0,1))
% 
% figure; errorbar(mean_ctrl_left,std_ctrl_left); ylim([-2,2]);
% hold on; errorbar(mean_pd_left,std_pd_left); ylim([-2,2]);
% set(gca,'XTick',[1:7],'XTickLabels',targets_s);
% title('PD vs CTRL, left striatum');
% 
% figure; errorbar(mean_ctrl_right,std_ctrl_right); ylim([-2,2]);
% hold on; errorbar(mean_pd_right,std_pd_right); ylim([-2,2]);
% set(gca,'XTick',[1:7],'XTickLabels',targets_s);
% title('PD vs CTRL, right striatum');
% 





%% Stats tests below:

%% stats tests surf area

for h=1:2
    for t=1:length(targets)
        
        [hyp, p]=ttest2(squeeze(surfarea(controls,h,t)),squeeze(surfarea(patients,h,t)));
        if(hyp==1)
            disp(sprintf('Surface area: ctrl vs pd, %s %s, p-value=%f',hemi{h},targets{t},p));
        end
    end
    
end


%% stats tests surf disp

for h=1:2
    for t=1:length(targets)
        
        [hyp, p]=ttest2(squeeze(meansurfdisp(controls,h,t)),squeeze(meansurfdisp(patients,h,t)));
        if(hyp==1)
            disp(sprintf('Displacement: ctrl vs pd, %s %s, p-value=%f',hemi{h},targets{t},p));
        end
    end
    
end


%% stats tests parc vol
% 
% for h=1:2
%     for t=1:length(targets)
%         
%         [hyp, p]=ttest2(squeeze(voldata(controls,h,t)),squeeze(voldata(patients,h,t)));
%         if(hyp==1)
%             disp(sprintf('Volume: ctrl vs pd, %s %s, p-value=%f',hemi{h},targets{t},p));
%         end
%     end
%     
% end

%% stats tests mean FA

for h=1:2
    for t=1:length(targets)
        
        [hyp, p]=ttest2(squeeze(mean_fa(controls,h,t)),squeeze(mean_fa(patients,h,t)));
        %if(hyp==1)
            if (p<0.05)
            disp(sprintf('FA: ctrl vs pd, %s %s, p-value=%f',hemi{h},targets{t},p));
        end
    end
    
end

%% Other stuff below: all commented for now
% 
% 
% %% compare vol with surf data
% 
% parcvol=importdata('striatum_withRostralMotor.maxProbDiffusionParcVolume.byHemi.csv');
% 
% 
% target_order=[3,2,6,1,5,4,7];
% 
% voldata=zeros(length(subjects),length(hemi),length(targets));
% 
% 
% for s=1:length(subjects)
%     structi=1;
%     for t=1:length(targets)
%         for h=1:2
%             
%             voldata(s,h,target_order(t))=parcvol.data(s,structi);
%             structi=structi+1;
%         end
%     end
%     
% end
% %% correlations between metrics..
% meanarea=squeeze(mean(surfarea(:,1,:),1));
% meanvol=squeeze(mean(voldata(:,1,:),1));
% for s=1:length(subjects)
%     area=surfarea(s,1,:);
%     vol=voldata(s,1,:);
%     disp(sprintf('corr subj area with vol: %s %02f',subjects{s},corr(area(:),vol(:))));
%     %disp(sprintf('corr subj area with mean vol: %s %02f',subjects{s},corr(area(:),meanvol(:))));
%     %disp(sprintf('corr subj vol with mean area: %s %02f',subjects{s},corr(vol(:),meanarea(:))));
%     %disp(sprintf('corr subj area with mean area: %s %02f',subjects{s},corr(area(:),meanarea(:))));
% end
% 
% 
% %% motor-exec area ratio
% %experimental..
% 
% %left hemi
% hemi=1;
% motor_exec_ratio=surfarea(:,hemi,6)./surfarea(:,hemi,2);
% 
% figure;
% for g=1:length(groups)
%     subplot(1,2,g);
%     boxplot(motor_exec_ratio(groups{g}));
%     title(group_name{g});
% end
% 
% figure;
% for g=1:length(groups)
%     histogram(motor_exec_ratio(groups{g}),12);
%     hold on;
%     
% end
% legend(group_name);
% 
% [motor_exec_ratio_sorted,sortind]=sort(motor_exec_ratio);
% subj_sorted_motor_exec_ratio=subjects(sortind);
% 
% 
% %% compare surf and volume parcellation
% 
% figure; scatter(surfarea(:),voldata(:)); xlabel('surface parcellation'); ylabel('volume parcellation');
% 
% corr(surfarea(:),voldata(:))
% 
% 
% %% save all 
% save(sprintf('stats_workspace_%s.mat',date));


end
