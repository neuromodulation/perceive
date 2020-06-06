function perceive_print(filename)

[fold,file,ext]=fileparts(filename);
if ~exist(fold,'dir')
    mkdir(fold);
end
print(gcf,fullfile(fold,file),'-dpng','-r300','-opengl');
print(gcf,fullfile(fold,file),'-dpdf','-r80');
