export interface DownloadItem {
    legislature: string;
    status: "archive" | "current";
    type: "acteurs" | "scrutins";
    url: string;
    filename: string;
}

export const items: DownloadItem[] = [
    // Archives
    {
        legislature: "16",
        status: "archive",
        type: "acteurs",
        url: "https://data.assemblee-nationale.fr/static/openData/repository/16/amo/acteurs_mandats_organes_divises/AMO50_acteurs_mandats_organes_divises.json.zip",
        filename: "AMO50_acteurs_mandats_organes_divises.json.zip",
    },
    {
        legislature: "16",
        status: "archive",
        type: "scrutins",
        url: "https://data.assemblee-nationale.fr/static/openData/repository/16/loi/scrutins/Scrutins.json.zip",
        filename: "Scrutins.json.zip",
    },
    {
        legislature: "17",
        status: "current",
        type: "acteurs",
        url: "https://data.assemblee-nationale.fr/static/openData/repository/17/amo/acteurs_mandats_organes_divises/AMO50_acteurs_mandats_organes_divises.json.zip",
        filename: "AMO50_acteurs_mandats_organes_divises.json.zip",
    },
    {
        legislature: "17",
        status: "current",
        type: "scrutins",
        url: "https://data.assemblee-nationale.fr/static/openData/repository/17/loi/scrutins/Scrutins.json.zip",
        filename: "Scrutins.json.zip",
    },
];
