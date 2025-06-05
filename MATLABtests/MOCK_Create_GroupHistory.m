for i = 2:3
    GroupHistory = perceive_GroupHistory(sprintf('Report_Json_Session_Report_MOCK%d.json', i));
    save(sprintf('Report_Json_Session_Report_MOCK%d_GroupHistory.mat', i),"GroupHistory")
end