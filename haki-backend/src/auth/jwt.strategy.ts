import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
    constructor(configService: ConfigService, private readonly usersService: UsersService, private readonly auth: AuthService) {
        super({
            jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
            ignoreExpiration: false,
            secretOrKey: configService.get<string>('JWT_SECRET')!,
        });
    }

    // ponytail: two DB lookups per request so bans and removed devices apply to issued tokens; cache if it shows up in profiling
    async validate(payload: any) {
        const user = await this.usersService.findOneById(payload.sub);
        if (!user || user.isBanned || !(await this.auth.sessionActive(payload.sid))) throw new UnauthorizedException();
        return { sub: user.id, username: user.username, role: user.role, sid: payload.sid };
    }
}
