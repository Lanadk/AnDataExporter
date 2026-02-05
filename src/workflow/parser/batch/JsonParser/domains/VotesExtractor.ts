import * as fs from 'fs';
import * as path from 'path';
import {Extractor} from "../../BatchProcessor";
import {
    Depute,
    GroupeParlementaire,
    Vote,
    VoteAgregat,
    VoteDepute,
    VoteGroupe,
    VoteGroupeAgregat
} from "../../types/IVotes";

interface DatabaseExport {
    deputes: Depute[];
    groupes: GroupeParlementaire[];
    votes: Vote[];
    votesGroupes: VoteGroupe[];
    votesDeputes: VoteDepute[];
    votesAgregats: VoteAgregat[];
    votesGroupesAgregats: VoteGroupeAgregat[];
}


export class VotesExtractor implements Extractor {
    private deputes: Set<string> = new Set();
    private groupes: Set<string> = new Set();
    private votes: Vote[] = [];
    private votesGroupes: VoteGroupe[] = [];
    private votesDeputes: VoteDepute[] = [];
    private votesAgregats: VoteAgregat[] = [];
    private votesGroupesAgregats: VoteGroupeAgregat[] = [];
    private errors: Array<{file: string, error: string}> = [];

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
            votes: this.votes,
            votesGroupes: this.votesGroupes,
            votesDeputes: this.votesDeputes,
            votesAgregats: this.votesAgregats,
            votesGroupesAgregats: this.votesGroupesAgregats,
            groupes: Array.from(this.groupes).map(id => ({
                id,
                nom: null
            })),
            deputes: Array.from(this.deputes).map(id => ({ id }))
        };
    }

    // Implem
    getErrors(): Array<{ file: string; error: string }> {
        return this.errors;
    }

    private extractData(data: any): void {
        const scrutin = data.scrutin || data;

        if (!scrutin.uid) {
            throw new Error('Missing uid');
        }

        // Extract scrutin metadata
        const scrutinData: Vote = {
            uid: scrutin.uid,
            numero: scrutin.numero || '',
            legislature: scrutin.legislature || '',
            date_vote: scrutin.dateScrutin || '',
            titre: scrutin.titre || scrutin.objet?.libelle || '',
            type_vote_code: scrutin.typeVote?.codeTypeVote || null,
            type_vote_libelle: scrutin.typeVote?.libelleTypeVote || null,
            type_majorite: scrutin.typeVote?.typeMajorite || null,
            resultat_code: scrutin.sort?.code || null,
            resultat_libelle: scrutin.sort?.libelle || null
        };
        this.votes.push(scrutinData);

        // Extract source aggregates
        if (scrutin.syntheseVote) {
            const agregats: VoteAgregat = {
                vote_uid: scrutin.uid,
                nombre_votants: parseInt(scrutin.syntheseVote.nombreVotants) || 0,
                suffrages_exprimes: parseInt(scrutin.syntheseVote.suffragesExprimes) || 0,
                suffrages_requis: parseInt(scrutin.syntheseVote.nbrSuffragesRequis) || 0,
                total_pour: parseInt(scrutin.syntheseVote.decompte?.pour) || 0,
                total_contre: parseInt(scrutin.syntheseVote.decompte?.contre) || 0,
                total_abstentions: parseInt(scrutin.syntheseVote.decompte?.abstentions) || 0,
                total_non_votants: parseInt(scrutin.syntheseVote.decompte?.nonVotants) || 0,
                total_non_votants_volontaires: parseInt(scrutin.syntheseVote.decompte?.nonVotantsVolontaires) || 0
            };
            this.votesAgregats.push(agregats);
        }

        // Extract groups and votes
        const ventilation = scrutin.ventilationVotes || scrutin.votes || scrutin.groupes;
        if (ventilation) {
            const organe = ventilation.organe || ventilation;
            const groupsData = organe.groupes?.groupe || organe.groupe || [];
            const groupsArray = Array.isArray(groupsData) ? groupsData : [groupsData];

            for (const group of groupsArray) {
                if (!group || !group.organeRef) continue;

                // Register groupe
                this.groupes.add(group.organeRef);

                // Extract scrutin_groupe
                const scrutinGroupe: VoteGroupe = {
                    vote_uid: scrutin.uid,
                    groupe_id: group.organeRef,
                    nombre_membres: parseInt(group.nombreMembresGroupe) || 0,
                    position_majoritaire: group.vote?.positionMajoritaire || ''
                };
                this.votesGroupes.push(scrutinGroupe);

                // Extract groupe aggregates source
                if (group.vote?.decompteVoix) {
                    const groupeAgregats: VoteGroupeAgregat = {
                        vote_uid: scrutin.uid,
                        groupe_id: group.organeRef,
                        pour: parseInt(group.vote.decompteVoix.pour) || 0,
                        contre: parseInt(group.vote.decompteVoix.contre) || 0,
                        abstentions: parseInt(group.vote.decompteVoix.abstentions) || 0,
                        non_votants: parseInt(group.vote.decompteVoix.nonVotants) || 0,
                        non_votants_volontaires: parseInt(group.vote.decompteVoix.nonVotantsVolontaires) || 0
                    };
                    this.votesGroupesAgregats.push(groupeAgregats);
                }

                // Extract individual votes
                const decompteNominatif = group.vote?.decompteNominatif;
                if (decompteNominatif) {
                    // Pour
                    this.extractVotes(scrutin.uid, group.organeRef, decompteNominatif.pours, 'pour');
                    // Contre
                    this.extractVotes(scrutin.uid, group.organeRef, decompteNominatif.contres, 'contre');
                    // Abstentions
                    this.extractVotes(scrutin.uid, group.organeRef, decompteNominatif.abstentions, 'abstention');
                    // Non votants
                    this.extractVotes(scrutin.uid, group.organeRef, decompteNominatif.nonVotants, 'non_votant');
                }
            }
        }
    }

    private extractVotes(scrutinUid: string, groupeId: string, votesData: any, position: string): void {
        if (!votesData) return;

        const voters = votesData.votant || [];
        const votersArray = Array.isArray(voters) ? voters : [voters];

        for (const voter of votersArray) {
            if (!voter.acteurRef) continue;

            // Register depute
            this.deputes.add(voter.acteurRef);

            const vote: VoteDepute = {
                vote_uid: scrutinUid,
                depute_id: voter.acteurRef,
                groupe_id: groupeId,
                mandat_ref: voter.mandatRef || '',
                position: position,
                cause_position: voter.causePositionVote || null,
                par_delegation: voter.parDelegation === 'true' || voter.parDelegation === true ? true : null
            };
            this.votesDeputes.push(vote);
        }
    }

    exportToJSON(outputPath: string): void {
        const deputesArray: Depute[] = Array.from(this.deputes).map(id => ({ id }));
        const groupesArray: GroupeParlementaire[] = Array.from(this.groupes).map(id => ({
            id,
            nom: null
        }));

        const exportData: DatabaseExport = {
            deputes: deputesArray,
            groupes: groupesArray,
            votes: this.votes,
            votesGroupes: this.votesGroupes,
            votesDeputes: this.votesDeputes,
            votesAgregats: this.votesAgregats,
            votesGroupesAgregats: this.votesGroupesAgregats
        };

        fs.writeFileSync(outputPath, JSON.stringify(exportData, null, 2), 'utf-8');

        console.log('='.repeat(50));
        console.log('EXPORT SUMMARY');
        console.log('='.repeat(50));
        console.log(`Deputes:                              ${deputesArray.length}`);
        console.log(`Groupes parlementaires:               ${groupesArray.length}`);
        console.log(`Scrutins:                             ${this.votes.length}`);
        console.log(`Scrutin groupes:                      ${this.votesGroupes.length}`);
        console.log(`Votes deputes:                        ${this.votesDeputes.length}`);
        console.log(`Scrutins agregats source:             ${this.votesAgregats.length}`);
        console.log(`Scrutin groupes agregats source:      ${this.votesGroupesAgregats.length}`);
        console.log('='.repeat(50));
        console.log(`\nExported to: ${outputPath}`);
        console.log('\n'.repeat(2));

        if (this.errors.length > 0) {
            console.log(`\nErrors: ${this.errors.length} files failed`);
            const errorsPath = outputPath.replace('.json', '-errors.json');
            fs.writeFileSync(errorsPath, JSON.stringify(this.errors, null, 2), 'utf-8');
            console.log(`Error details: ${errorsPath}`);
        }
    }

    exportSeparateFiles(outputDir: string): void {
        if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

        const deputesArray: Depute[] = Array.from(this.deputes).map(id => ({ id }));
        const groupesArray: GroupeParlementaire[] = Array.from(this.groupes).map(id => ({
            id,
            nom: null
        }));

        fs.writeFileSync(
            path.join(outputDir, 'deputes.json'),
            JSON.stringify(deputesArray, null, 2),
            'utf-8'
        );

        fs.writeFileSync(
            path.join(outputDir, 'groupes_parlementaires.json'),
            JSON.stringify(groupesArray, null, 2),
            'utf-8'
        );

        fs.writeFileSync(
            path.join(outputDir, 'scrutins.json'),
            JSON.stringify(this.votes, null, 2),
            'utf-8'
        );

        fs.writeFileSync(
            path.join(outputDir, 'scrutin_groupes.json'),
            JSON.stringify(this.votesGroupes, null, 2),
            'utf-8'
        );

        fs.writeFileSync(
            path.join(outputDir, 'votes_deputes.json'),
            JSON.stringify(this.votesDeputes, null, 2),
            'utf-8'
        );

        fs.writeFileSync(
            path.join(outputDir, 'scrutins_agregats_source.json'),
            JSON.stringify(this.votesAgregats, null, 2),
            'utf-8'
        );

        fs.writeFileSync(
            path.join(outputDir, 'scrutin_groupes_agregats_source.json'),
            JSON.stringify(this.votesGroupesAgregats, null, 2),
            'utf-8'
        );

        console.log('='.repeat(50));
        console.log('EXPORT SUMMARY');
        console.log('='.repeat(50));
        console.log(`Deputes:                              ${deputesArray.length}`);
        console.log(`Groupes parlementaires:               ${groupesArray.length}`);
        console.log(`Scrutins:                             ${this.votes.length}`);
        console.log(`Scrutin groupes:                      ${this.votesGroupes.length}`);
        console.log(`Votes deputes:                        ${this.votesDeputes.length}`);
        console.log(`Scrutins agregats source:             ${this.votesAgregats.length}`);
        console.log(`Scrutin groupes agregats source:      ${this.votesGroupesAgregats.length}`);
        console.log('='.repeat(50));
        console.log(`\nExported to: ${outputDir}/`);
        console.log('Files:');
        console.log('  - deputes.json');
        console.log('  - groupes_parlementaires.json');
        console.log('  - scrutins.json');
        console.log('  - scrutin_groupes.json');
        console.log('  - votes_deputes.json');
        console.log('  - scrutins_agregats_source.json');
        console.log('  - scrutin_groupes_agregats_source.json');
        console.log('\n'.repeat(2));
    }
}
