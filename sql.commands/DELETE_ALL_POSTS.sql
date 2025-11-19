-- ==============================================
-- Delete All Posts with Cascade
-- ==============================================
-- This script safely deletes all posts and all related records
-- Run this in psql: \i DELETE_ALL_POSTS.sql
-- Or copy-paste the commands below

-- Step 1: Check current post count
SELECT COUNT(*) as total_posts FROM social.posts;

-- Step 2: Delete related records first (in dependency order)
-- Order matters: Delete child records before parent records

-- Delete likes on comments first (because comments will be deleted)
-- Likes can reference either posts OR comments
DELETE FROM social.likes 
WHERE comment_id IS NOT NULL;
-- Expected: DELETE X (where X is the number of comment likes)

-- Delete nested comment replies (comments that reference other comments)
DELETE FROM social.comments 
WHERE parent_id IS NOT NULL;
-- Expected: DELETE X (where X is the number of nested replies)

-- Delete top-level comments (which reference posts)
DELETE FROM social.comments;
-- Expected: DELETE X (where X is the number of top-level comments)

-- Delete likes on posts
DELETE FROM social.likes 
WHERE post_id IS NOT NULL;
-- Expected: DELETE X (where X is the number of post likes)

-- Delete shares (references posts)
DELETE FROM social.shares;
-- Expected: DELETE X (where X is the number of shares)

-- Delete post analytics (references posts)
DELETE FROM social.post_analytics;
-- Expected: DELETE X (where X is the number of analytics records)

-- Delete notifications related to posts (if any)
-- Check if notifications table has post_id column
-- If it does, uncomment the line below:
-- DELETE FROM social.notifications WHERE post_id IS NOT NULL;

-- Step 3: Delete all posts
DELETE FROM social.posts;
-- Expected: DELETE X (where X is the number of posts)

-- Step 4: Verify deletion
SELECT COUNT(*) as remaining_posts FROM social.posts;
-- Should return 0

SELECT COUNT(*) as remaining_analytics FROM social.post_analytics;
-- Should return 0

SELECT COUNT(*) as remaining_shares FROM social.shares;
-- Should return 0

SELECT COUNT(*) as remaining_comments FROM social.comments;
-- Should return 0

-- ==============================================
-- ALTERNATIVE: Using TRUNCATE with CASCADE (faster, but more dangerous)
-- ==============================================
-- WARNING: TRUNCATE cannot be rolled back and is faster but more dangerous
-- This will delete all data from posts and cascade to related tables
-- Only use if you're absolutely sure you want to delete everything
-- 
-- TRUNCATE TABLE social.posts CASCADE;
-- 
-- Note: TRUNCATE CASCADE will only work if foreign keys support it
-- If you get errors, use the manual deletion approach above

-- ==============================================
-- ALTERNATIVE: Temporarily disable constraints (advanced)
-- ==============================================
-- WARNING: This is dangerous and should only be used by experienced DBAs
-- 
-- BEGIN;
-- 
-- -- Disable foreign key constraints temporarily
-- ALTER TABLE social.post_analytics DISABLE TRIGGER ALL;
-- ALTER TABLE social.shares DISABLE TRIGGER ALL;
-- ALTER TABLE social.comments DISABLE TRIGGER ALL;
-- ALTER TABLE social.likes DISABLE TRIGGER ALL;
-- 
-- -- Delete posts
-- DELETE FROM social.posts;
-- 
-- -- Re-enable constraints
-- ALTER TABLE social.post_analytics ENABLE TRIGGER ALL;
-- ALTER TABLE social.shares ENABLE TRIGGER ALL;
-- ALTER TABLE social.comments ENABLE TRIGGER ALL;
-- ALTER TABLE social.likes ENABLE TRIGGER ALL;
-- 
-- COMMIT;

