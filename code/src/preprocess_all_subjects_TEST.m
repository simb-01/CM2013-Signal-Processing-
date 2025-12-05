function Subjects = preprocess_all_subjects_TEST(subjects_data)

    fs = 125;  % Sampling rate (Hz)
    nrSubjects = numel(subjects_data);

    for i = 1:nrSubjects
        data = subjects_data{i}.preprocessed_data;  % 1 x nrChannels cell array.
        nrChannels = numel(data);
        preprocessed_subj_data = cell(1, nrChannels);

        fprintf('\n--- Preprocessing subject %d/%d ---\n', i, nrSubjects);
        processed_data = zeros(size(data));

        for ch = 1:nrChannels
            channel_data = data{ch};
            preprocessed_subj_data{ch} = preprocess_TEST(channel_data);
        end

        subjects_data{i}.preprocessed_data = preprocessed_subj_data;

    end
    Subjects = subjects_data;
end
