function generate_report(Y_pred, Y_test)
%% Generate report - simple text report

fprintf('\n=== SLEEP SCORING REPORT ===\n');

% Calculate metrics
accuracy = sum(Y_pred == Y_test) / length(Y_test) * 100;
fprintf('Overall Accuracy: %.2f%%\n', accuracy);

% Per-class accuracy
stage_names = {'Wake', 'N1', 'N2', 'N3', 'REM'};
for stage = 0:4
    idx = Y_test == stage;
    if sum(idx) > 0
        stage_acc = sum(Y_pred(idx) == Y_test(idx)) / sum(idx) * 100;
        fprintf('%s Accuracy: %.2f%% (%d epochs)\n', stage_names{stage+1}, stage_acc, sum(idx));
    end
end

fprintf('\nReport generation complete\n');
end
