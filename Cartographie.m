function CartographieII()
    % ================================================================
    % 1. CREATION DE LA FENETRE PRINCIPALE UNIQUE
    % ================================================================
    fig = uifigure('Name', 'ESIGELEC - Analyseur et Pipeline de Champ Proche', ...
                   'Position', [100, 100, 1050, 650], ...
                   'Color', [0.95, 0.96, 0.98]);
    
    % Stockage des données internes à l'application
    appData = struct('dossierSource', '', 'fichiersValides', []);
    
    % Couleurs de la charte graphique
    couleurBleu = [41, 128, 185] / 255;
    couleurGris = [44, 62, 80] / 255;

    % ================================================================
    % 2. PANNEAU LATERAL DE CONTROLE (GAUCHE)
    % ================================================================
    pnlControle = uipanel(fig, 'Title', ' CONFIGURATION & FILTRES', ...
                              'Position', [20, 20, 260, 610], ...
                              'BackgroundColor', 'w', ...
                              'ForegroundColor', couleurGris, ...
                              'FontWeight', 'bold', 'FontSize', 12);

    % Sélection du dossier
    uibutton(pnlControle, 'Text', 'Sélectionner le dossier CSV', ...
                          'Position', [15, 530, 225, 35], ...
                          'BackgroundColor', couleurBleu, ...
                          'FontColor', 'w', 'FontWeight', 'bold', ...
                          'ButtonPushedFcn', @btnDossierCallback);
                      
    lblDossier = uilabel(pnlControle, 'Text', 'Aucun dossier chargé.', ...
                                      'Position', [15, 500, 225, 20], ...
                                      'FontAngle', 'italic', 'FontColor', [0.5 0.5 0.5]);

    % Menu de sélection du champ
    uilabel(pnlControle, 'Text', 'Composante du champ :', 'Position', [15, 440, 225, 22], 'FontWeight', 'bold');
    dropChamp = uidropdown(pnlControle, 'Position', [15, 415, 225, 25], 'Items', {'En attente...'});

    % Menu de sélection de la fréquence
    uilabel(pnlControle, 'Text', 'Fréquence de mesure :', 'Position', [15, 355, 225, 22], 'FontWeight', 'bold');
    dropFreq = uidropdown(pnlControle, 'Position', [15, 330, 225, 25], 'Items', {'En attente...'});

    % Menu de sélection de la hauteur
    uilabel(pnlControle, 'Text', 'Altitude Z (Hauteur) :', 'Position', [15, 270, 225, 22], 'FontWeight', 'bold');
    dropH = uidropdown(pnlControle, 'Position', [15, 245, 225, 25], 'Items', {'En attente...'});

    % Bouton d'affichage dynamique
    btnTracer = uibutton(pnlControle, 'Text', 'Afficher la Cartographie', ...
                                      'Position', [15, 175, 225, 40], ...
                                      'BackgroundColor', [46, 204, 113] / 255, ...
                                      'FontColor', 'w', 'FontWeight', 'bold', 'FontSize', 12, ...
                                      'Enable', 'off', ...
                                      'ButtonPushedFcn', @btnTracerCallback);

    % Bouton d'export de la carte active uniquement
    btnExportSeul = uibutton(pnlControle, 'Text', 'Exporter cette carte en PNG', ...
                                         'Position', [15, 125, 225, 35], ...
                                         'BackgroundColor', [52, 152, 219] / 255, ...
                                         'FontColor', 'w', 'FontWeight', 'bold', ...
                                         'Enable', 'off', ...
                                         'ButtonPushedFcn', @btnExportSeulCallback);

    % Bouton d'export de masse
    btnExport = uibutton(pnlControle, 'Text', 'Tout exporter (90 PNG)', ...
                                      'Position', [15, 75, 225, 30], ...
                                      'BackgroundColor', [230, 126, 34] / 255, ...
                                      'FontColor', 'w', 'FontWeight', 'bold', ...
                                      'Enable', 'off', ...
                                      'ButtonPushedFcn', @btnExportCallback);
                                  
    % Indicateur d'état
    lblStatus = uilabel(pnlControle, 'Text', 'Statut : Prêt', ...
                                     'Position', [15, 20, 225, 20], ...
                                     'FontColor', couleurGris);

    % ================================================================
    % 3. ZONE DE TRACÉ INTEGRÉE (DROITE)
    % ================================================================
    ax = uiaxes(fig, 'Position', [300, 40, 720, 580], ...
                     'BackgroundColor', 'w');
    title(ax, 'Veuillez charger un dossier contenant les exports CSV de HFSS', 'Color', [0.5 0.5 0.5]);
    grid(ax, 'on');
    ax.GridLineStyle = ':';

    % ================================================================
    % 4. FONCTIONS DE CALLBACKS (LOGIQUE INTERNE NESTED)
    % ================================================================
    
    % Action : Clic sur Sélectionner dossier
    function btnDossierCallback(~, ~)
        dossier = uigetdir(pwd, 'Sélectionnez le dossier Export_CSV');
        if dossier == 0, return; end
        
        appData.dossierSource = dossier;
        [~, nomDossierCourt] = fileparts(dossier);
        lblDossier.Text = ['Dossier : .../' nomDossierCourt];
        
        fichiers = dir(fullfile(dossier, '*.csv'));
        fichiers = fichiers(~strcmp({fichiers.name}, 'Resultats_MinMax.csv'));
        
        if isempty(fichiers)
            uialert(fig, 'Aucun fichier de cartographie valide trouvé dans ce dossier.', 'Erreur dossier');
            return;
        end
        
        champs = {}; freqs = {}; hauteurs = {};
        fichiersValides = struct('name', {}, 'champ', {}, 'freq', {}, 'hauteur', {});
        
        for idx = 1:length(fichiers)
            tokens = split(strrep(fichiers(idx).name, '.csv', ''), '_');
            if length(tokens) >= 3
                c = tokens{1}; f = tokens{2}; h = tokens{3};
                champs = [champs; c]; freqs = [freqs; f]; hauteurs = [hauteurs; h];
                
                fichiersValides(end+1).name = fichiers(idx).name;
                fichiersValides(end).champ = c;
                fichiersValides(end).freq = f;
                fichiersValides(end).hauteur = h;
            end
        end
        
        appData.fichiersValides = fichiersValides;
        
        dropChamp.Items = unique(champs);
        dropFreq.Items = unique(freqs);
        dropH.Items = unique(hauteurs);
        
        btnTracer.Enable = 'on';
        btnExportSeul.Enable = 'on'; % Activation du nouveau bouton
        btnExport.Enable = 'on';
        lblStatus.Text = sprintf('Statut : %d cartes détectées', length(fichiersValides));
        title(ax, 'Fichiers chargés avec succès. Prêt à l''affichage.', 'Color', couleurGris);
    end

    % Action : Clic sur Afficher la cartographie
    function btnTracerCallback(~, ~)
        champSel = dropChamp.Value;
        freqSel = dropFreq.Value;
        hSel = dropH.Value;
        
        nomFichierCible = sprintf('%s_%s_%s.csv', champSel, freqSel, hSel);
        cheminComplet = fullfile(appData.dossierSource, nomFichierCible);
        
        if ~exist(cheminComplet, 'file')
            uialert(fig, 'Cette combinaison spécifique n''existe pas dans le dossier.', 'Fichier introuvable');
            return;
        end
        
        lblStatus.Text = 'Statut : Tracé en cours...';
        drawnow;
        
        opts = detectImportOptions(cheminComplet);
        opts.VariableNamingRule = 'preserve';
        data = readtable(cheminComplet, opts);
        
        U = data{:, 1}; V = data{:, 2}; Z = data{:, 3};
        u_u = unique(U); v_u = unique(V);
        Nu = length(u_u); Nv = length(v_u);
        
        U_grid = reshape(U, Nv, Nu);
        V_grid = reshape(V, Nv, Nu);
        Z_grid = reshape(Z, Nv, Nu);
        
        cla(ax);
        contourf(ax, U_grid, V_grid, Z_grid, 255, 'LineColor', 'none');
        colormap(ax, 'jet');
        grid(ax, 'on');
        
        if contains(nomFichierCible, 'NearE')
            clim(ax, [-60 75]);
        else
            clim(ax, [-112 28]);
        end
        
        title(ax, sprintf('Composante %s | Fréquence : %s | Altitude : %s', champSel, freqSel, hSel));
        xlabel(ax, 'Axe local U (mm)', 'FontWeight', 'bold');
        ylabel(ax, 'Axe local V (mm)', 'FontWeight', 'bold');
        
        lblStatus.Text = 'Statut : Affichage mis à jour';
    end

    % Action : Clic sur Exporter uniquement la carte active
    function btnExportSeulCallback(~, ~)
        champSel = dropChamp.Value;
        freqSel = dropFreq.Value;
        hSel = dropH.Value;
        
        nomFichierCible = sprintf('%s_%s_%s.csv', champSel, freqSel, hSel);
        cheminComplet = fullfile(appData.dossierSource, nomFichierCible);
        
        if ~exist(cheminComplet, 'file')
            uialert(fig, 'Veuillez d''abord charger un dossier de données valide.', 'Erreur d''exportation');
            return;
        end
        
        % Ouverture d'un sélecteur de fichier de sauvegarde système
        nomDefaut = strrep(nomFichierCible, '.csv', '_MATLAB.png');
        [fichierOut, dossierOut] = uiputfile('*.png', 'Enregistrer la cartographie active sous...', fullfile(appData.dossierSource, nomDefaut));
        
        if fichierOut == 0, return; end % Annulation utilisateur
        
        lblStatus.Text = 'Statut : Génération du PNG...';
        drawnow;
        
        % Extraction et reconstruction de la matrice pour impression propre
        opts = detectImportOptions(cheminComplet);
        opts.VariableNamingRule = 'preserve';
        data = readtable(cheminComplet, opts);
        
        U = data{:, 1}; V = data{:, 2}; Z = data{:, 3};
        u_u = unique(U); v_u = unique(V);
        U_grid = reshape(U, length(v_u), length(u_u));
        V_grid = reshape(V, length(v_u), length(u_u));
        Z_grid = reshape(Z, length(v_u), length(u_u));
        
        % Rendu HD dans une figure invisible (pour garder la colorbar avec la légende complète)
        figTmp = figure('Visible', 'off');
        contourf(U_grid, V_grid, Z_grid, 255, 'LineColor', 'none');
        colormap('jet'); colorbar; shading interp; grid on;
        
        if contains(nomFichierCible, 'NearE')
            clim([-60 75]); ylabel(colorbar, 'Champ électrique (dB V/m)');
        else
            clim([-112 28]); ylabel(colorbar, 'Champ Magnétique (dB A/m)');
        end
        
        xlabel('Axe local U (mm)'); ylabel('Axe local V (mm)');
        title(sprintf('Champ Proche : %s | %s | %s', champSel, freqSel, hSel));
        
        % Sauvegarde physique de l'image
        saveas(figTmp, fullfile(dossierOut, fichierOut));
        close(figTmp);
        
        lblStatus.Text = 'Statut : Image exportée avec succès !';
    end

    % Action : Clic sur Tout exporter en PNG
    function btnExportCallback(~, ~)
        dossierOut = uigetdir(appData.dossierSource, 'Où sauvegarder les 90 fichiers PNG ?');
        if dossierOut == 0, return; end
        
        total = length(appData.fichiersValides);
        lblStatus.Text = 'Statut : Export global...';
        drawnow;
        
        for idx = 1:total
            f = appData.fichiersValides(idx);
            lblStatus.Text = sprintf('Export : %d/%d', idx, total);
            drawnow;
            
            cheminIn = fullfile(appData.dossierSource, f.name);
            opts = detectImportOptions(cheminIn);
            opts.VariableNamingRule = 'preserve';
            data = readtable(cheminIn, opts);
            
            U = data{:, 1}; V = data{:, 2}; Z = data{:, 3};
            u_u = unique(U); v_u = unique(V);
            U_grid = reshape(U, length(v_u), length(u_u));
            V_grid = reshape(V, length(v_u), length(u_u));
            Z_grid = reshape(Z, length(v_u), length(u_u));
            
            figTmp = figure('Visible', 'off');
            contourf(U_grid, V_grid, Z_grid, 255, 'LineColor', 'none');
            colormap('jet'); colorbar; shading interp; grid on;
            
            if contains(f.name, 'NearE')
                clim([-60 75]); ylabel(colorbar, 'Champ électrique (dB V/m)');
            else
                clim([-112 28]); ylabel(colorbar, 'Champ Magnétique (dB A/m)');
            end
            
            xlabel('Axe local U (mm)'); ylabel('Axe local V (mm)');
            title(sprintf('%s | %s | %s', f.champ, f.freq, f.hauteur));
            
            nomPng = fullfile(dossierOut, strrep(f.name, '.csv', '_MATLAB.png'));
            saveas(figTmp, nomPng);
            close(figTmp);
        end
        
        uiconfirm(fig, 'L''intégralité des cartographies a été exportée en haute définition.', ...
                      'Export terminé', 'Options', {'Parfait'}, 'Icon', 'success');
        lblStatus.Text = 'Statut : Prêt';
    end
end