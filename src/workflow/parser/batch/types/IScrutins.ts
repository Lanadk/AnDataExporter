export interface Depute {
    id: string;
}

export interface GroupeParlementaire {
    id: string;
    nom: string | null;
}

export interface Scrutin {
    uid: string;
    numero: string;
    legislature: string;
    date_scrutin: string;
    titre: string | null;
    type_scrutin_code: string | null;
    type_scrutin_libelle: string | null;
    type_majorite: string | null;
    resultat_code: string | null;
    resultat_libelle: string | null;
}

export interface ScrutinGroupe {
    scrutin_uid: string;
    groupe_id: string;
    nombre_membres: number;
    position_majoritaire: string;
}

export interface VoteDepute {
    scrutin_uid: string | null;
    depute_id: string | null;
    groupe_id: string | null;
    mandat_ref: string | null;
    position: string | null;
    cause_position: string | null;
    par_delegation: boolean | null;
}

export interface ScrutinAgregat {
    scrutin_uid: string;
    nombre_votants: number;
    suffrages_exprimes: number;
    suffrages_requis: number;
    total_pour: number;
    total_contre: number;
    total_abstentions: number;
    total_non_votants: number;
    total_non_votants_volontaires: number;
}

export interface ScrutinGroupeAgregat {
    scrutin_uid: string;
    groupe_id: string;
    pour: number;
    contre: number;
    abstentions: number;
    non_votants: number;
    non_votants_volontaires: number;
}