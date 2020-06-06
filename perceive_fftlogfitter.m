function [nyd,nyl]=perceive_fftlogfitter(f,data,flow,fhigh)
%[nyd]=fftlogfitter(f,data)
%data should be in channels x frequencies
if exist('flow','var')
    flowl = flow(1);
    flowh = flow(2);
else
    flowl = 3;
    flowh = 5;
end
if exist('fhigh','var')
    fhighl = fhigh(1);
    fhighh = fhigh(2);
else
    fhighl=35;
    fhighh=40;
end


for a= 1:size(data,1)
    y = data(a,:);
    fl=log(f);
    yl=log(y)';
    fvector=[fl(find(round(f)==flowl):find(round(f)==flowh));fl(find(round(f)==fhighl):find(round(f)==fhighh))];
    yvector=[yl(find(round(f)==flowl):find(round(f)==flowh));yl(find(round(f)==fhighl):find(round(f)==fhighh))];
    nyl=exp(polyval(polyfit(fvector,yvector,1),fl));
    ny=exp(yl-polyval(polyfit(fvector,yvector,1),fl));
    nyd(:,a)=ny;
end


% 
% figure;
% subplot(8,1,1:2);
% h=loglog(f,y,f,nyl,'color','k','LineWidth',3);xlim([2 80]);
% set(gca,'XTick',[0:5:40])
% set(h(2),'LineStyle','--','LineWidth',1.5,'color',[0.5 0.5 0.5]);
% subplot(8,1,3:4);
% h=plot(f,y,f,nyl,'color','k','LineWidth',3);xlim([2 80]);
% set(gca,'XTick',[0:5:40])
% set(h(2),'LineStyle','--','LineWidth',1.5,'color',[0.5 0.5 0.5]);
% subplot(8,1,5:8);
% h=plot(f,nyd,'color','k','LineWidth',3);xlim([2 80]);
% set(gca,'XTick',[0:5:40])
% set(h(2),'LineStyle','--','LineWidth',1.5,'color',[0.5 0.5 0.5]);

