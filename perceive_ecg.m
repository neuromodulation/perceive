function ecg=perceive_ecg(data,fs,plotit)

if ~exist('fs','var')
    fs = 250;
end
if ~exist('plotit')
    plotit=1;
end

dwindow=round(fs/2) ;%*1/(40/60);;
dmove = fs/10;
ns = size(data,2);
i =[1+dwindow:dmove:ns-dwindow-1]';
for a = 1:length(i)
    x(a,:) = data([i(a)-dwindow:i(a)+dwindow]);
end

ndata = zeros(1,4*dwindow);
nt=linspace(-2*dwindow/fs,size(ndata,2)/fs-2*dwindow/fs,size(ndata,2));

ndata(1,perceive_sc(nt,0):perceive_sc(nt,0)+size(x,2)-1)=x(1,:);n=0;
for a = 2:size(x,1)
    [r,l]=xcorr(nanmean(ndata,1),x(a,:),fs);
    [mr,mi]=max(r);
    tlag = l(mi);
    if tlag >0 
        n=n+1;
        ndata(n,tlag:tlag+size(x,2)-1)=x(a,:);
    end
end

nt=linspace(-2*dwindow/fs,size(ndata,2)/fs-2*dwindow/fs,size(ndata,2));
mdata = nanmean(ndata);

[absm,imax]=findpeaks(abs(mdata),'SortStr','descend','NPeaks',15);
np=0.05;iim=[];iin=[];
while isempty(iim) || isempty(iin)
    np=np+.025;
    pkrange=imax(1)-round(fs*np):imax(1)+round(fs*np);
    [m,iim,wm]=findpeaks(mdata(pkrange),'SortStr','descend','NPeaks',1);
    [n,iin,wn]=findpeaks(-mdata(pkrange),'SortStr','descend','NPeaks',1);
end
iim=iim+pkrange(1)-1;
iin=iin+pkrange(1)-1;
pdif=absm(1)./nansum(absm(2:end))*100;

if iin(1)<iim(1)
    a1=n;
    a2=m; 
    ii1 = iin(1);
    ii2 = iim(1);
    ii=iin(1);
    w1=wn(1);
    w2 = wm(1);
else
    a1=m;
    a2=n;
    ii1=iim(1);
    ii2=iin(1);
    w1=wm(1);
    w2=wn(1);
end
disp(pdif)

% ecg_cut=ii-round(0.05*fs):ii+round(0.1*fs);
ecg_cut=ii1-round(w1(1)):ii2+round(w2(1));
ecg.template = mdata(ecg_cut);

r=zeros(size(data));
corrdata=[];
for a = 1:ns-size(ecg_cut,2)-1
    corrdata(:,a) = data(1,a:a+size(ecg_cut,2)-1)';
end
r = corr(corrdata,ecg.template').^2; 
ecg.r = r;

h=max(findpeaks(r))-.05:-0.01:0.2;
thr=[];
for a=1:length(h)
    [p,ix]=findpeaks(r,'MinPeakHeight',h(a));
    if ~isempty(ix)
        dd=60./(diff(ix)/250);
        thr(a)=nansum(dd>55&dd<120)./std(dd);
    end
end

[p,ithr]=max(thr);
ecg.thresh=h(ithr);

[pks,i]=findpeaks(r,'MinPeakHeight',ecg.thresh,'MinPeakDistance',round(fs/2));
ecg.intervals = diff(i)./fs;
ecg.heartrate=60/(nanmedian(diff(i))/fs);
ecg.sdata = data;
ecg.zdata = data;
ecg.nandata = data;
cbins = zeros(size(data));
for a = 1:length(pks)
    ic=i(a):i(a)+size(ecg_cut,2)-1;
    lm = fitlm(data(1,ic)',ecg.template');
    ecg.sdata(ic)=lm.predict;
    ecg.r2(a) = lm.Rsquared.Adjusted;
    ecg.n = numel(pks);
    cbins(ic)=1;
end
ecg.nandata(find(cbins))=nan;
ecg.zdata(find(cbins))=0;
ecg.idata = fillmissing(ecg.nandata,'pchip');
ecg.pctartefact = nansum(cbins)/ns*100;
ecg.msartefact = nansum(cbins)/fs;
ecg.ecglength = length(ecg.template)/fs;
t = linspace(0,ns/fs,ns);

[pow,f,rpow]=perceive_fft(data(~isnan(data)),fs,fs*4);
try
    [pow,f,rnpow]=perceive_fft(ecg.nandata(~isnan(ecg.nandata)),fs,fs*4);
catch
    warning('Not enough data for FFT left.')
    rnpow = zeros(size(f));
end

if (ecg.heartrate<55 || ecg.heartrate>120) || ecg.n <= 0.5*ns/fs || (ii2-ii1)/fs > 0.075 || pdif < 20
    disp('No reliable ECG detection possible.')
    ecg.found = 0;
else
    ecg.found = 1;
end

if plotit
    figure
    subplot(2,2,1);
    plot(nt,ndata','linewidth',0.1,'color',[.9 .9 .9]);
    hold on
    plot(nt,mdata','color','k');
    hold on
    scatter(nt(iim(1)),mdata(iim(1)),'bo');
    scatter(nt(iin(1)),mdata(iin(1)),'ro');
    hold on
    plot(nt(ecg_cut),ecg.template,'color','r');
    xlabel('Time [s]')
    ylabel('Amplitude')
    xlim([nt(ii1)-.2 nt(ii2)+.2]);
    detstring = {'Unreliable or no ECG','Consistent ECG'};
    title([detstring{ecg.found+1} ' detected.'])
    subplot(2,2,2)
    plot(f,rpow,f,rnpow,'linewidth',2);
    xlim([4 30]);
    legend('original','cleaned');
    xlabel('Frequency [Hz]')
    ylabel('Relative spectral power [%]')
    title(['PDIF: ' num2str(pdif,2) ' HR: ' num2str(ecg.heartrate,3) '/min  N = ' num2str(ecg.n,3)]);
    subplot(2,2,3:4);
    plot(t,data,'color','r');
    hold on
    plot(t,ecg.idata,'color','k');
    legend('original','cleaned');
    ylabel('Amplitude')
    xlabel('Time [s]')
end