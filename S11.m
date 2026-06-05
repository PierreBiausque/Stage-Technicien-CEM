clc; clear; close all;

% =========================================================================
% 1. LECTURE DES DONNEES EXPORTEES DE HFSS
% =========================================================================
nomFichier = 'S Parameter Plot 1.csv';

if ~exist(nomFichier, 'file')
    error('Le fichier %s est introuvable dans le dossier actuel.', nomFichier);
end

% Configuration de l'import pour respecter les en-têtes exacts de HFSS
opts = detectImportOptions(nomFichier);
opts.VariableNamingRule = 'preserve'; 
data = readtable(nomFichier, opts);

% Extraction des vecteurs de données
Frequence = data{:, 'Freq [GHz]'};
S11_dB = data{:, 'dB(S(1,1)) []'};

% =========================================================================
% 2. RECHERCHE AUTOMATIQUE DE LA RESONANCE
% =========================================================================
[minS11, idxMin] = min(S11_dB);
freqResonance = Frequence(idxMin);

fprintf('--- ANALYSE FREQUENTIELLE ANTENNE ---\n');
fprintf('Fréquence de résonance détectée : %.2f GHz\n', freqResonance);
fprintf('Valeur du paramètre S11 : %.2f dB\n', minS11);

% =========================================================================
% 3. GENERATION DU GRAPHIQUE PROFESSIONNEL
% =========================================================================
fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100, 100, 800, 550]);

% Tracé du S11
plot(Frequence, S11_dB, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Paramètre S_{11}');
hold on;

% Ajout de la ligne repère des -10 dB (Seuil d'adaptation)
yline(-10, 'r--', 'Seuil d''adaptation (-10 dB)', ...
      'LabelVerticalAlignment', 'bottom', ...
      'LabelHorizontalAlignment', 'left', ...
      'LineWidth', 1.5, 'FontSize', 10);

% Marquage du point de résonance (Minimum)
plot(freqResonance, minS11, 'ro', 'MarkerSize', 9, ...
     'MarkerFaceColor', 'r', 'DisplayName', 'Fréquence de résonance');

% Habillage et grille
grid on;
ax = gca;
ax.GridLineStyle = ':';
ax.GridAlpha = 0.5;
ax.FontSize = 11;

% Titres et étiquettes
xlabel('Fréquence (GHz)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Coefficient de réflexion S_{11} (dB)', 'FontSize', 12, 'FontWeight', 'bold');
title('Coefficient de réflexion S_{11} en fonction de la fréquence', 'FontSize', 13, 'FontWeight', 'bold');

% Définition des limites des axes
xlim([min(Frequence) max(Frequence)]);
ylim([floor(min(S11_dB))-2, 2]);

% Ajout d'une boîte d'information sur le graphique
infobox = {sprintf('Résonance : %.2f GHz', freqResonance), ...
           sprintf('S_{11} : %.2f dB (Adapté)', minS11)};
annotation('textbox', [0.55 0.2 0.3 0.1], 'String', infobox, ...
           'BackgroundColor', 'w', 'EdgeColor', 'k', ...
           'LineWidth', 1, 'FontSize', 10, 'FitBoxToText', 'on');

% =========================================================================
% 4. SAUVEGARDE AUTOMATIQUE DE L'IMAGE
% =========================================================================
nomImageSortie = 'Parametre_S11_Antenne.png';
saveas(fig, nomImageSortie);
close(fig);

disp('-------------------------------------------------------------------');
disp(['Graphique enregistré avec succès sous : ', nomImageSortie]);