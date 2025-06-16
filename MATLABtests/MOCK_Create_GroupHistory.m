for i = 2:3
     js = perceive_GroupHistory(sprintf('Report_Json_Session_Report_MOCK%d.json', i));
     GroupHistory = js.GroupHistory;
    save(sprintf('Report_Json_Session_Report_MOCK%d_GroupHistory.mat', i),"GroupHistory")
end