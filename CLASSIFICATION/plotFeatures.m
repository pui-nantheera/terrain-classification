function plotFeatures(featuresData, labels, dimension, plotHyperplane, model)
% plot features and 2 classes

if nargin < 4
    plotHyperplane = 0;
end

typelebels = unique(labels);
class1 = labels==typelebels(1);
class2 = labels==typelebels(2);

figure; 
if dimension==2
    plot(featuresData(class1, 1), featuresData(class1, 2), 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 7); hold on
    plot(featuresData(class2, 1), featuresData(class2, 2), 'k^', 'MarkerFaceColor', 'm', 'MarkerSize', 7);
else
    plot3(featuresData(class1, 1), featuresData(class1, 2), featuresData(class1, 3), 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 7); hold on
    plot3(featuresData(class2, 1), featuresData(class2, 2), featuresData(class2, 3), 'k^', 'MarkerFaceColor', 'm', 'MarkerSize', 7);
    zlabel('feature #3');
end
xlabel('feature #1'); ylabel('feature #2');
legend(['class ',num2str(typelebels(1))],['class ',num2str(typelebels(2))], 'location', 'best');
grid on

% plot hyperplane
if plotHyperplane
    
    if dimension==2
        x1plot = linspace(min(featuresData(:,1)), max(featuresData(:,1)), 200)';
        x2plot = linspace(min(featuresData(:,2)), max(featuresData(:,2)), 200)';
        [X1, X2] = meshgrid(x1plot, x2plot);
        vals = zeros(size(X1));
        for i = 1:size(X1, 2)
            this_X = [X1(:, i), X2(:, i)];
            vals(:, i) = svmpredict(zeros(size(this_X,1),1), this_X, model);
        end
        
        % Plot the SVM boundary
        contour(X1, X2, vals, [0 0], 'Color', 'b');
    else
        display('under construction ... sorry')
    end
end

hold off;