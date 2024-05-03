function perceive_print(filename, mode)

arguments
    filename {mustBeText}
    mode    {mustBeMember(mode,{'png','pdf'})} = 'png'
end

[fold,file,ext]=fileparts(filename);
if ~exist(fold,'dir')
    mkdir(fold);
end

switch mode
    case 'png'
        print(gcf,fullfile(fold,file),'-dpng','-r300','-opengl');
    case 'pdf'
        % save the current orientation
        or=get(gcf,'PaperOrientation');
        % set landscape orientation
        set(gcf,'PaperOrientation','Landscape');
        % print with the 'bestfit' option to make the whole plot visible
        print(gcf,fullfile(fold,file),'-dpdf','-r80','-bestfit');
        % restore the orientation
        set(gcf,'PaperOrientation',or);
end
