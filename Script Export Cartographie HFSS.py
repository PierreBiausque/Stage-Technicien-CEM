import os
import csv

# ==========================================
# INITIALISATION HFSS
# ==========================================
oDesktop.RestoreWindow()
oProject = oDesktop.GetActiveProject()
oDesign = oProject.GetActiveDesign()
oModule = oDesign.GetModule("ReportSetup")

# ==========================================
# PARAMETRES UTILISATEUR
# ==========================================

# Nom du setup en multi-frequencies
setup_name = "Setup1 : LastAdaptive"

# Nom du plan de mesures
radiation_surface = "Mesures"

# Plage de frequences
frequencies_hfss = ["0.1GHz", "0.2GHz", "0.5GHz", "0.8GHz", "1GHz", "2.42GHz"]

# Plage de hauteurs de mesure
heights = ["1mm", "3mm", "5mm"]

# Liste des noms de champs a cartographier
fields = ["NearEX", "NearEY", "NearEZ", "NearHX", "NearHY", "NearHZ"]

# Dictionnaire de conversion GHz vers MHz
freq_to_mhz = {
    "0.1GHz": "100",
    "0.2GHz": "200",
    "0.5GHz": "500",
    "0.8GHz": "800",
    "1GHz": "1000",
    "2.42GHz" : "2420"
}

# ==========================================
# CREATION DU DOSSIER D'EXPORT
# ==========================================
project_path = oProject.GetPath()
# Indiquer le nom du dossier d'export
export_dir = os.path.join(project_path, "Export_Cartographies_Plages")

if not os.path.exists(export_dir):
    os.makedirs(export_dir)

# Nom du fichier des valeurs électriques minimales et maximales
excel_file_path = os.path.join(export_dir, "Resultats_MinMax.csv")

# ==========================================
# BOUCLE DE GENERATION ET D'EXPORT
# ==========================================
with open(excel_file_path, mode='w') as csv_file:
    writer = csv.writer(csv_file, delimiter=';', lineterminator='\n')
    # Nom des colonnes dans le fichier d'export
    writer.writerow(["Frequence (MHz)", "Hauteur (mm)", "Champ", "Minimum dB", "Maximum dB"])

    # Boucle de plage de frequences
    for freq in frequencies_hfss:
        #Boucle de plage d'hauteurs
        for h in heights:
            # Boucle de liste de champs
            for field in fields:
                
                # Formatage des noms
                f_mhz_name = freq_to_mhz.get(freq, freq) + "MHz"
                report_name = "{}_{}_{}".format(field, f_mhz_name, h)
                # Indique le champ en cours d'analyse
                quantity = "dB({})".format(field)
                
                # 1. Creation du Rectangular Contour Plot
                oModule.CreateReport(report_name, "Near Fields", "Rectangular Contour Plot", setup_name, 
                    [
                        "Context:=", radiation_surface
                    ], 
                    [
                        # Indique la frequence en cours de la boucle
                        "Freq:=", [freq],
                        # Indique la hauteur en cours de la boucle
                        "$H_mesure:=", [h],
                        "_u:=", ["All"],
                        "_v:=", ["All"]
                    ], 
                    [
                        "X Component:=", "_v",
                        "Y Component:=", "_u",
                        "Z Component:=", [quantity]
                    ], [])
                
                # 2. Dynamisation des bornes Min/Max selon le type de champ (E ou H)
                if "NearE" in field:
                    scale_min = "-42" # Borne Max pour les champs E
                    scale_max = "90"  # Borne Min pour les champs E
                else:
                    scale_min = "-87" # Borne Max pour les champs H
                    scale_max = "40"  # Borne Min pour les champs H

                # Passage en mode FRINGE avec les limites specifiees et haute resolution
                prop_server_name = "{}: Plot {}".format(report_name, quantity)
                
                try:
                    oModule.ChangeProperty(
                        [
                            "NAME:AllTabs",
                            [
                                "NAME:Contour",
                                [
                                    "NAME:PropServers", 
                                    prop_server_name
                                ],
                                [
                                    "NAME:ChangedProps",
                                    [
                                        # Permet l'affichage des lignes en Fringe
                                        "NAME:IsoValType",
                                        "Value:="        , "Fringe"
                                    ],
                                    [
                                        # Definition des plages Max et Min de l'echelle de valeur
                                        "NAME:Scale Type",
                                        "Value:="        , "Specify Limits"
                                    ],
                                    [
                                        "NAME:Min",
                                        "Value:="        , scale_min
                                    ],
                                    [
                                        "NAME:Max",
                                        "Value:="        , scale_max
                                    ],
                                    [
                                        # Definition du nombre de ligne de champs
                                        "NAME:Num. Contours",
                                        "Value:="		, "255"
                                    ]
                                ]
                            ]
                        ])
                except:
                    # Si erreur, on passe au suivant sans bloquer le script
                    pass
                
                # 3. Exportation de l'image
                img_path = os.path.join(export_dir, report_name + ".png")
                oModule.ExportImageToFile(report_name, img_path, 0, 0)
                
                # 4. Exportation des donnees pour extraire Min/Max
                temp_data_path = os.path.join(export_dir, "temp_data.csv")
                oModule.ExportToFile(report_name, temp_data_path, False)
                
                min_val = float('inf')
                max_val = float('-inf')
                
                # 5. Lecture du fichier temporaire pour trouver les extremes
                # 5. Lecture du fichier temporaire pour trouver les extremes
                if os.path.exists(temp_data_path):
                    with open(temp_data_path, 'r') as data_file:
                        lines = data_file.readlines()
                        for line in lines[1:]:
                            cols = line.split(',')
                            if len(cols) >= 3:
                                try:
                                    val = float(cols[2].strip())
                                    if val < min_val: min_val = val
                                    if val > max_val: max_val = val
                                except:
                                    pass
                    
                    os.remove(temp_data_path)
                
                if min_val == float('inf'):
                    min_val = "N/A"
                    max_val = "N/A"

                # 6. ecriture dans le fichier Excel (CSV)
                f_mhz = freq_to_mhz.get(freq, freq)
                h_mm = h.replace("mm", "")
                writer.writerow([f_mhz, h_mm, field, min_val, max_val])
                
                # 7. Suppression du plot dans HFSS pour garder le projet leger
                oModule.DeleteReports([report_name])

oDesktop.AddMessage(oProject.GetName(), oDesign.GetName(), 0, "Exportation terminee avec succes. Fichiers dans : " + export_dir)