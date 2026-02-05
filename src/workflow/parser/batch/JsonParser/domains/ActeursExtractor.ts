import * as fs from 'fs';
import * as path from 'path';
import {
    Acteur,
    ActeurAdresseMail,
    ActeurAdressePostale,
    ActeurReseauSocial,
    ActeurTelephone
} from "../../types/IActeurs";
import {Extractor} from "../../BatchProcessor";


export interface ActeursExport {
    acteurs: Acteur[];
    acteurs_adresses_postales: ActeurAdressePostale[];
    acteurs_adresses_mails: ActeurAdresseMail[];
    acteurs_reseaux_sociaux: ActeurReseauSocial[];
    acteurs_telephones: ActeurTelephone[];
}

export class ActeursExtractor implements Extractor {
    private acteurs: Acteur[] = [];
    private adressesPostales: ActeurAdressePostale[] = [];
    private adressesMails: ActeurAdresseMail[] = [];
    private reseauxSociaux: ActeurReseauSocial[] = [];
    private telephones: ActeurTelephone[] = [];
    public errors: Array<{ file: string; error: string }> = [];

    loadFile(filePath: string): any {
        const content = fs.readFileSync(filePath, 'utf-8');
        return JSON.parse(content);
    }

    // Implem
    processFile(filePath: string): void {
        try {
            const data = this.loadFile(filePath);
            this.extractData(data);
        } catch (error) {
            this.errors.push({
                file: path.basename(filePath),
                error: error instanceof Error ? error.message : String(error)
            });
        }
    }
    // Implem
    getTables(): Record<string, any[]> {
        return {
            acteurs: this.acteurs,
            acteurs_adresses_postales: this.adressesPostales,
            acteurs_adresses_mails: this.adressesMails,
            acteurs_reseaux_sociaux: this.reseauxSociaux,
            acteurs_telephones: this.telephones
        };
    }
    // Implem
    getErrors(): Array<{ file: string; error: string }> {
        return this.errors;
    }

    private extractData(data: any): void {
        const acteur = data.acteur || data;
        if (!acteur.uid) throw new Error('Missing uid');

        const uid = typeof acteur.uid === 'string' ? acteur.uid : acteur.uid['#text'];

        // --- Main acteur info ---
        this.acteurs.push({
            uid,
            civilite: acteur.etatCivil?.ident?.civ || null,
            prenom: acteur.etatCivil?.ident?.prenom || null,
            nom: acteur.etatCivil?.ident?.nom || null,
            nom_alpha: acteur.etatCivil?.ident?.alpha || null,
            trigramme: acteur.etatCivil?.ident?.trigramme || null,
            date_naissance: acteur.etatCivil?.infoNaissance?.dateNais || null,
            ville_naissance: acteur.etatCivil?.infoNaissance?.villeNais || null,
            departement_naissance: acteur.etatCivil?.infoNaissance?.depNais || null,
            pays_naissance: acteur.etatCivil?.infoNaissance?.paysNais || null,
            date_deces: acteur.etatCivil?.dateDeces || null,
            profession_libelle: acteur.profession?.libelleCourant || null,
            profession_categorie: acteur.profession?.socProcINSEE?.catSocPro || null,
            profession_famille: acteur.profession?.socProcINSEE?.famSocPro || null,
            uri_hatvp: acteur.uri_hatvp || null
        });

        if (!acteur.adresses?.adresse) return;

        const adresses = Array.isArray(acteur.adresses.adresse)
            ? acteur.adresses.adresse
            : [acteur.adresses.adresse];

        for (const adresse of adresses) {
            if (!adresse) continue;
            const xsiType = adresse['@xsi:type'];

            switch (xsiType) {
                case 'AdressePostale_Type':
                    this.adressesPostales.push({
                        acteur_uid: uid,
                        uid_adresse: adresse.uid || '',
                        type_code: adresse.type || null,
                        type_libelle: adresse.typeLibelle || null,
                        intitule: adresse.intitule || null,
                        numero_rue: adresse.numeroRue || null,
                        nom_rue: adresse.nomRue || null,
                        complement_adresse: adresse.complementAdresse || null,
                        code_postal: adresse.codePostal || null,
                        ville: adresse.ville || null
                    });
                    break;

                case 'AdresseMail_Type':
                    this.adressesMails.push({
                        acteur_uid: uid,
                        uid_adresse: adresse.uid || '',
                        type_code: adresse.type || null,
                        type_libelle: adresse.typeLibelle || null,
                        email: adresse.valElec || ''
                    });
                    break;

                case 'AdresseSiteWeb_Type': {
                    const typeLibelle = (adresse.typeLibelle || '').toLowerCase();
                    let plateforme = 'site_web';
                    if (typeLibelle.includes('facebook')) plateforme = 'facebook';
                    else if (typeLibelle.includes('twitter')) plateforme = 'twitter';
                    else if (typeLibelle.includes('instagram')) plateforme = 'instagram';
                    else if (typeLibelle.includes('linkedin')) plateforme = 'linkedin';
                    else if (typeLibelle.includes('youtube')) plateforme = 'youtube';

                    this.reseauxSociaux.push({
                        acteur_uid: uid,
                        uid_adresse: adresse.uid || '',
                        type_code: adresse.type || null,
                        type_libelle: adresse.typeLibelle || null,
                        plateforme,
                        identifiant: adresse.valElec || ''
                    });
                    break;
                }

                case 'AdresseTelephonique_Type':
                    this.telephones.push({
                        acteur_uid: uid,
                        uid_adresse: adresse.uid || '',
                        type_code: adresse.type || null,
                        type_libelle: adresse.typeLibelle || null,
                        adresse_rattachement: adresse.adresseDeRattachement || null,
                        numero: adresse.valElec || ''
                    });
                    break;
            }
        }
    }

    exportToJSON(outputPath: string): void {
        const exportData: ActeursExport = {
            acteurs: this.acteurs,
            acteurs_adresses_postales: this.adressesPostales,
            acteurs_adresses_mails: this.adressesMails,
            acteurs_reseaux_sociaux: this.reseauxSociaux,
            acteurs_telephones: this.telephones
        };
        fs.writeFileSync(outputPath, JSON.stringify(exportData, null, 2), 'utf-8');
    }

    exportSeparateFiles(outputDir: string): void {
        if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

        fs.writeFileSync(path.join(outputDir, 'acteurs.json'), JSON.stringify(this.acteurs, null, 2));
        fs.writeFileSync(path.join(outputDir, 'acteurs_adresses_postales.json'), JSON.stringify(this.adressesPostales, null, 2));
        fs.writeFileSync(path.join(outputDir, 'acteurs_adresses_mails.json'), JSON.stringify(this.adressesMails, null, 2));
        fs.writeFileSync(path.join(outputDir, 'acteurs_reseaux_sociaux.json'), JSON.stringify(this.reseauxSociaux, null, 2));
        fs.writeFileSync(path.join(outputDir, 'acteurs_telephones.json'), JSON.stringify(this.telephones, null, 2));
    }
}
