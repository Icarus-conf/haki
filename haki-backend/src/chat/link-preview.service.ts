import { Injectable, Logger } from '@nestjs/common';
import ogs from 'open-graph-scraper';

export interface LinkPreviewData {
    title?: string;
    description?: string;
    image?: string;
    url: string;
}

@Injectable()
export class LinkPreviewService {
    private readonly logger = new Logger(LinkPreviewService.name);

    async getLinkPreview(url: string): Promise<LinkPreviewData> {
        try {
            const { result } = await ogs({ url });

            return {
                title: result.ogTitle,
                description: result.ogDescription,
                image: result.ogImage?.[0]?.url,
                url: result.ogUrl || url,
            };
        } catch (error) {
            this.logger.warn(`Failed to fetch OG data for ${url}: ${error.message}`);
            return { url };
        }
    }
}
