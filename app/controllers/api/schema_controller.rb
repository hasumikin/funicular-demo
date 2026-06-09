class Api::SchemaController < ApplicationController
  def user
    # Schema.build inlines the User model's ActiveRecord validations into each
    # attribute entry. Only the attributes declared here are introspected
    # (allowlist); `except` drops kinds we don't want on the client; uniqueness
    # is database-only and is skipped automatically.
    render json: Funicular::Schema.build(
      User,
      attributes: {
        "id" => { type: "integer", readonly: true },
        "username" => { type: "string", readonly: true },
        "display_name" => { type: "string", readonly: false },
        "birthday" => { type: "string", readonly: false },
        "has_avatar" => { type: "boolean", readonly: true },
        "avatar" => {
          type: "binary",
          readonly: true,
          upload_endpoint: "/users/:id/avatar"
        }
      },
      endpoints: {
        "find" => { method: "GET", path: "/users/:id" },
        "update" => { method: "PATCH", path: "/users/:id" }
      },
      except: { username: [:format] }
    )
  end

  def session
    render json: {
      attributes: {
        "username" => { type: "string", readonly: false },
        "password" => { type: "string", readonly: false }
      },
      endpoints: {
        "create" => { method: "POST", path: "/login" },
        "destroy" => { method: "DELETE", path: "/logout" },
        "current" => { method: "GET", path: "/current_user" }
      }
    }
  end

  def channel
    render json: {
      attributes: {
        "id" => { type: "integer", readonly: true },
        "name" => { type: "string", readonly: true },
        "description" => { type: "string", readonly: true }
      },
      endpoints: {
        "all" => { method: "GET", path: "/channels" },
        "find" => { method: "GET", path: "/channels/:id" }
      }
    }
  end

  def post
    render json: {
      attributes: {
        "id" => { type: "integer", readonly: true },
        "title" => { type: "string", readonly: true },
        "body" => { type: "string", readonly: true },
        "author_name" => { type: "string", readonly: true },
        "published_at" => { type: "string", readonly: true },
        "excerpt" => { type: "string", readonly: true },
        "comments" => { type: "array", readonly: true }
      },
      endpoints: {
        "all" => { method: "GET", path: "/posts" },
        "find" => { method: "GET", path: "/posts/:id" }
      }
    }
  end

  def comment
    render json: {
      attributes: {
        "id" => { type: "integer", readonly: true },
        "post_id" => { type: "integer", readonly: false },
        "body" => { type: "string", readonly: false },
        "author_name" => { type: "string", readonly: true },
        "created_at" => { type: "string", readonly: true }
      },
      endpoints: {
        "create" => { method: "POST", path: "/comments" }
      }
    }
  end
end
