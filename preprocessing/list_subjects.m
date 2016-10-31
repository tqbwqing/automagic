function subjects = list_subjects(root_folder)
    subs = dir(root_folder);
    isub = [subs(:).isdir];
    subjects = {subs(isub).name}';
    subjects(ismember(subjects,{'.','..'})) = [];
end