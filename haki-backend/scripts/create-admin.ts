import { NestFactory } from '@nestjs/core';
import * as bcrypt from 'bcrypt';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/users/users.service';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const usersService = app.get(UsersService);
    const dataSource = app.get(DataSource);

    const adminEmail = 'admin@example.com';
    const adminUsername = 'admin';
    const adminPassword = 'admin123';

    console.log('Checking for existing user...');
    let user = await usersService.findByEmail(adminEmail);

    if (!user) {
        console.log('User not found. Creating new user...');
        const hashedPassword = await bcrypt.hash(adminPassword, 10);
        // Note: create method might throw if username exists but email doesn't. 
        // We assume mostly fresh db or unique constraint handles it.
        try {
            user = await usersService.create(adminUsername, adminEmail, hashedPassword);
        } catch (e) {
            // If username exists, try fetching by username
            user = await usersService.findOne(adminUsername);
            if (!user) {
                console.error('Failed to create user:', e);
                process.exit(1);
            }
        }
    }

    console.log(`Setting role 'admin' for user ${user.username} (${user.id})...`);

    await dataSource.getRepository('User').update(user.id, { role: 'admin' });

    console.log('------------------------------------------------');
    console.log('Admin Setup Complete');
    console.log(`Username: ${user.username}`);
    console.log(`Email:    ${adminEmail}`);
    console.log(`Password: ${adminPassword}`); // Only if we created it/know it. If it existed, password is unchanged. 
    console.log('------------------------------------------------');

    await app.close();
}

bootstrap();
